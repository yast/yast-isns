# encoding: utf-8

# File:	clients/isns.ycp
# Package:	Configuration of isns
# Summary:	Main file
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: isns.ycp 28597 2006-03-06 11:29:38Z mzugec $
#
# Main file for isns configuration. Uses all other files.
module Yast
  module IsnsDialogsInclude
    def initialize_isns_dialogs(include_target)
      textdomain "isns"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "IsnsServer"
      Yast.import "CWMTab"
      Yast.import "CWM"
      Yast.import "CWMServiceStart"
      Yast.import "CWMFirewallInterfaces"
      Yast.import "TablePopup"

      Yast.include include_target, "isns/helps.rb"
      Yast.include include_target, "isns/widgets.rb"

      # store current here
      @current_tab = "service"

      @tabs_descr = {
        # first tab - service status and firewall
        "service"             => {
          "header"       => _("Service"),
          "contents"     => VBox(
            VStretch(),
            HBox(
              HStretch(),
              HSpacing(1),
              VBox(
                "ipaddress",
                VSpacing(2),
                "auto_start_up",
                VSpacing(2),
                "firewall",
                VSpacing(2)
              ),
              HSpacing(1),
              HStretch()
            ),
            VStretch()
          ),
          "widget_names" => ["ipaddress", "auto_start_up", "firewall"]
        },
        # second tab - iSCSI Nodes
        "members"             => {
          "header"       => _("iSCSI Nodes"),
          "contents"     => VBox(
            VSpacing(1),
            HBox(HSpacing(5), VBox("iscsi_nodes_display"), HSpacing(5)),
            VSpacing(1)
          ),
          "widget_names" => ["iscsi_nodes_display"]
        },
        # third tab - Discovery Domains
        "discoverydomains"    => {
          "header"       => _("Discovery Domains"),
          "contents"     => VBox(
            HBox(HStretch(), VBox("dd_display"), HStretch()),
            VStretch(),
            HBox(HStretch(), VBox("dd_display_members"), HStretch())
          ),
          "widget_names" => ["dd_display", "dd_display_members"]
        },
        # fourth tab - discovery domain sets
        "discoverydomainsets" => {
          "header"       => _("Discovery Domains Sets"),
          "contents"     => VBox(
            HBox(HStretch(), VBox("dds_display"), HStretch()),
            VStretch(),
            HBox(HStretch(), VBox("dds_display_members"), HStretch())
          ),
          "widget_names" => ["dds_display", "dds_display_members"]
        }
      }


      @widgets = {
        "auto_start_up"       => CWMServiceStart.CreateAutoStartWidget(
          {
            "get_service_auto_start" => fun_ref(
              IsnsServer.method(:GetStartService),
              "boolean ()"
            ),
            "set_service_auto_start" => fun_ref(
              IsnsServer.method(:SetStartService),
              "void (boolean)"
            ),
            "start_auto_button"      => _("When &Booting"),
            "start_manual_button"    => _("&Manually"),
            "help"                   => Builtins.sformat(
              CWMServiceStart.AutoStartHelpTemplate,
              _("When Booting"),
              _("Manually")
            )
          }
        ),
        "ipaddress"           => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            HBox(
              InputField(
                Id(:isnsaddress),
                Opt(:hstretch),
                _("Address of iSNS Server")
              )
            )
          ),
          "init"          => fun_ref(method(:initAddress), "void (string)"),
          "handle"        => fun_ref(
            method(:handleAddress),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "ipaddress", "")
        },
        "firewall"            => CWMFirewallInterfaces.CreateOpenFirewallWidget(
          { "services" => ["service:isns"], "display_details" => true }
        ),
        "iscsi_nodes_display" => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Heading(_("iSCSI Nodes")),
            Table(
              Id(:members_table),
              Header(_("iSCSI Node Name"), _("Node Type")),
              []
            ),
            Left(HBox(PushButton(Id(:delete), _("Delete"))))
          ),
          "init"          => fun_ref(method(:initISCSI), "void (string)"),
          "handle"        => fun_ref(
            method(:handleISCSI),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "iscsi_display", "")
        },
        "dd_display"          => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Heading(_("Discovery Domains")),
            HBox(
              VSpacing(5),
              Table(
                Id(:dd_table),
                Opt(:notify, :immediate),
                Header(_("Discovery Domain Name")),
                []
              )
            ),
            Left(
              HBox(
                PushButton(Id(:add), _("Create Discovery Domain")),
                PushButton(Id(:delete), _("Delete")),
                HSpacing(25)
              )
            )
          ),
          "init"          => fun_ref(
            method(:initDiscoveryDomain),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleDiscoveryDomain),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "dd_display", "")
        },
        "dd_display_members"  => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Heading(_("Discovery Domain Members")),
            HBox(
              VSpacing(10),
              Table(
                Id(:dd_members_table),
                Header(_("iSCSI Node Name"), _("Node Type")),
                []
              )
            ),
            Left(
              HBox(
                PushButton(Id(:addiscsinode), _("Add Existing iSCSI Node")),
                PushButton(Id(:createmember), _("Create iSCSI Node Member")),
                PushButton(Id(:remove), _("Remove"))
              )
            )
          ),
          "init"          => fun_ref(
            method(:initDDISCSIMembers),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleDiscoveryDomainMembers),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "dd_display_members", "")
        },
        "dds_display"         => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Heading(_("Discovery Domains Sets")),
            HBox(
              VSpacing(5),
              Table(
                Id(:dds_table),
                Opt(:notify, :immediate),
                Header(_("Discovery Domain Set Name")),
                []
              )
            ),
            Left(
              HBox(
                PushButton(Id(:add), _("Create Discovery Domain Set")),
                PushButton(Id(:delete), _("Delete")),
                HSpacing(25)
              )
            )
          ),
          "init"          => fun_ref(
            method(:initDiscoveryDomainSet),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleDiscoveryDomainSet),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "dds_display", "")
        },
        "dds_display_members" => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Heading(_("Discovery Domain Set Members")),
            HBox(
              VSpacing(10),
              Table(
                Id(:dds_members_table),
                Header(_("Discovery Domain Name")),
                []
              )
            ),
            Left(
              HBox(
                PushButton(Id(:adddd), _("Add Discovery Domain")),
                PushButton(Id(:remove), _("Remove"))
              )
            )
          ),
          "init"          => fun_ref(
            method(:initDiscoveryDomainSetMembers),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleDiscoveryDomainSetMembers),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "dds_display_members", "")
        }
      }
    end

    # Summary dialog
    # @return dialog result
    # Main dialog - tabbed
    def SummaryDialog
      caption = _("iSNS Service")
      #curr_target = "";
      widget_descr = {
        "tab" => CWMTab.CreateWidget(
          {
            "tab_order"    => [
              "service",
              "members",
              "discoverydomains",
              "discoverydomainsets"
            ],
            "tabs"         => @tabs_descr,
            "widget_descr" => @widgets,
            "initial_tab"  => @current_tab,
            "tab_help"     => _("<h1>iSNS Service</h1>")
          }
        )
      }
      contents = VBox("tab")
      w = CWM.CreateWidgets(
        ["tab"],
        Convert.convert(
          widget_descr,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      )
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )
      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      Wizard.HideBackButton
      #    Wizard::SetContentsButtons(caption, contents, help, Label::NextButton (), Label::FinishButton ());
      #    Wizard::HideBackButton();

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      ret
    end
  end
end
