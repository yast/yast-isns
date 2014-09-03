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
  module IsnsWidgetsInclude
    def initialize_isns_widgets(include_target)
      textdomain "isns"
      Yast.import "Label"
      Yast.import "IsnsServer"
      Yast.import "String"
      Yast.import "Report"
    end

    #	**************** global funcions and variables *****
    def DiscoveryDomainDetailDialog(values_before)
      values_before = deep_copy(values_before)
      ret_map = {}
      dd_dialog = VBox(
        Heading(_("Create New Discovery Domain")),
        HSpacing(50),
        HWeight(
          3,
          InputField(Id(:ddentry), Opt(:hstretch), _("Discovery Domain Name"))
        ),
        ButtonBox(
          PushButton(Id(:ok), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        ),
        VSpacing(1)
      )
      UI.OpenDialog(dd_dialog)

      ret = :nil
      while ret != :ok && ret != :cancel
        enable = false
        ret = Convert.to_symbol(UI.UserInput)
      end

      if ret == :cancel
        ret_map = {}
      else
        dd_name = Convert.to_string(UI.QueryWidget(:ddentry, :Value))
        IsnsServer.addDD(@address, dd_name)
        ret_map = { "VALUE" => dd_name }
      end
      UI.CloseDialog
      deep_copy(ret_map)
    end

    def CreateNode(values_before)
      values_before = deep_copy(values_before)
      ret_map = {}
      node_dialog = HBox(
        HSpacing(5),
        VBox(
          VSpacing(1),
          Left(
            HWeight(
              3,
              InputField(Id(:nodeentry), Opt(:hstretch), _("iSCSI Node Name"))
            )
          ),
          Left(
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          ),
          VSpacing(1)
        ),
        HSpacing(5)
      )

      UI.OpenDialog(node_dialog)

      ret = :nil
      while ret != :ok && ret != :cancel
        enable = false
        ret = Convert.to_symbol(UI.UserInput)
      end

      if ret == :cancel
        ret_map = {}
      else
        value = Convert.to_string(UI.QueryWidget(:nodeentry, :Value))
        ret_map = { "VALUE" => value }
      end
      UI.CloseDialog
      deep_copy(ret_map)
    end


    def DisplayAllMembersDialog(dd_name, dd_id)
      ret_map = {}
      iscsi_member_dialog = VBox(
        Heading(_("Add iSCSI node to discovery domain")),
        Label(dd_name),
        HSpacing(100),
        Heading(_("Available Nodes to Add")),
        HBox(
          VSpacing(10),
          Table(Id(:members_table), Header(_("Name"), _("Node Type")), [])
        ),
        Left(
          HBox(
            PushButton(Id(:add), _("Add Node")),
            PushButton(Id(:exit), _("Done"))
          )
        )
      )
      UI.OpenDialog(iscsi_member_dialog)

      initDiscoveryDomainPotentialISCSI(dd_id)

      ret = :nil
      while ret != :exit
        enable = false
        ret = Convert.to_symbol(UI.UserInput)
        if ret == :add
          Builtins.y2milestone("Add a node")
          index = UI.QueryWidget(Id(:members_table), :CurrentItem)
          iqn = Ops.get_string(
            Convert.to_term(
              UI.QueryWidget(Id(:members_table), term(:Item, index))
            ),
            1,
            ""
          )
          IsnsServer.addDDMember(@address, dd_id, iqn)
          initDiscoveryDomainPotentialISCSI(dd_id)
        end
      end

      UI.CloseDialog
      deep_copy(ret_map)
    end

    def initISCSI(key)
      count = 0
      type = _("Target or Initiator")
      inc_items = []

      checkISNS

      Builtins.foreach(IsnsServer.readISCSI(@address)) do |key2|
        inc_items = Builtins.add(
          inc_items,
          Item(
            Id(count),
            Ops.get_string(key2, "NODE", ""),
            Ops.get_string(key2, "TYPE", "")
          )
        )
        count = Ops.add(count, 1)
      end

      UI.ChangeWidget(Id(:members_table), :Items, inc_items)

      nil
    end
    def initDiscoveryDomainPotentialISCSI(key)
      count = 0
      type = _("Target or Initiator")
      inc_items = []
      iscsinode = ""
      ddmembers = []
      found = "FALSE"

      ddmembers = IsnsServer.readDDMembers(@address, key)

      Builtins.foreach(IsnsServer.readISCSI(@address)) do |iscsinode2|
        found = "FALSE"
        Builtins.foreach(ddmembers) do |ddmember|
          if Ops.get_string(ddmember, "NODE", "") ==
              Ops.get_string(iscsinode2, "NODE", "")
            found = "TRUE"
          end
        end
        if found == "FALSE"
          inc_items = Builtins.add(
            inc_items,
            Item(
              Id(count),
              Ops.get_string(iscsinode2, "NODE", ""),
              Ops.get_string(iscsinode2, "TYPE", "")
            )
          )
          count = Ops.add(count, 1)
        end
      end

      UI.ChangeWidget(Id(:members_table), :Items, inc_items)

      nil
    end
    def initDDISCSIMembers(key)
      count = 0
      index = ""
      ddid = ""
      inc_items = []

      Builtins.y2milestone("initDDISCSIMembers key is:%1", key)
      if key == "dd_display_members"
        key = Convert.to_string(UI.QueryWidget(Id(:dd_table), :CurrentItem))
      end

      ddid = key
      Builtins.foreach(IsnsServer.readDDMembers(@address, ddid)) do |result|
        Builtins.y2milestone("iscsiMembers: %1", key)
        inc_items = Builtins.add(
          inc_items,
          Item(
            Id(count),
            Ops.get_string(result, "NODE", ""),
            Ops.get_string(result, "TYPE", "")
          )
        )
        count = Ops.add(count, 1)
      end

      UI.ChangeWidget(Id(:dd_members_table), :Items, inc_items)

      nil
    end
    def initDiscoveryDomain(key)
      count = 0
      index = ""
      inc_items = []

      checkISNS

      Builtins.foreach(IsnsServer.readDD(@address)) do |dd|
        if count == 0
          index = dd
          count = 1
        else
          inc_items = Builtins.add(inc_items, Item(Id(index), dd))
          count = 0
        end
      end

      UI.ChangeWidget(Id(:dd_table), :Items, inc_items)

      nil
    end

    def handleISCSI(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "Activated"
        case Ops.get_symbol(event, "WidgetID")
          when :delete
            @del = UI.QueryWidget(Id(:members_table), :CurrentItem)
            if @del != nil
              if Popup.ContinueCancel(_("Really delete the selected item?"))
                discoverydomainsetname = Ops.get_string(
                  Convert.to_term(
                    UI.QueryWidget(Id(:members_table), term(:Item, @del))
                  ),
                  1,
                  ""
                )
                IsnsServer.deleteISCSI(@address, discoverydomainsetname)
                initISCSI("")
              else
                Builtins.y2milestone("Delete canceled")
              end
            end
        end
      end

      nil
    end

    def handleDiscoveryDomain(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "SelectionChanged"
        Builtins.y2milestone("selectionChangedEvent")
        dd_id = Convert.to_string(UI.QueryWidget(Id(:dd_table), :CurrentItem))
        Builtins.y2milestone("selectionChangedEvent - dd-id:%1", dd_id)
        initDDISCSIMembers(dd_id)
      elsif Ops.get_string(event, "EventReason", "") == "Activated"
        Builtins.y2milestone("handleDiscoveryDomainCalled:Activated")
        case Ops.get_symbol(event, "WidgetID")
          when :delete
            @del = Convert.to_string(
              UI.QueryWidget(Id(:dd_table), :CurrentItem)
            )
            if @del != nil
              if Popup.ContinueCancel(_("Really delete this domain?"))
                IsnsServer.deleteDD(@address, @del)
                initDiscoveryDomain("")
              else
                Builtins.y2milestone("Delete canceled")
              end
            end
          when :add
            @add_map = DiscoveryDomainDetailDialog({ "VALUE" => "" })
            if @add_map != {}
              #    IsnsServer::addDD(address, add_map["VALUE"]:"");
              initDiscoveryDomain("")
            end
        end
      end

      nil
    end

    def handleDiscoveryDomainMembers(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "Activated"
        case Ops.get_symbol(event, "WidgetID")
          when :delete
            # domain deleted, but we get this event so update the members table
            dd_id = Convert.to_string(
              UI.QueryWidget(Id(:dd_table), :CurrentItem)
            )
            initDDISCSIMembers(dd_id)
          when :remove
            iqn = UI.QueryWidget(Id(:dd_members_table), :CurrentItem)
            dd_name = Ops.get_string(
              Convert.to_term(
                UI.QueryWidget(Id(:dd_members_table), term(:Item, iqn))
              ),
              1,
              ""
            )
            dd_id = Convert.to_string(
              UI.QueryWidget(Id(:dd_table), :CurrentItem)
            )
            IsnsServer.deleteDDMember(@address, dd_id, dd_name)
            initDDISCSIMembers(dd_id)
          when :addiscsinode
            dd_id = Convert.to_string(
              UI.QueryWidget(Id(:dd_table), :CurrentItem)
            )
            dd_name = Ops.get_string(
              Convert.to_term(UI.QueryWidget(Id(:dd_table), term(:Item, dd_id))),
              1,
              ""
            )
            add_map1 = DisplayAllMembersDialog(dd_name, dd_id)
            initDDISCSIMembers(dd_id)
          when :createmember
            dd_id = Convert.to_string(
              UI.QueryWidget(Id(:dd_table), :CurrentItem)
            )
            dd_name = Ops.get_string(
              Convert.to_term(UI.QueryWidget(Id(:dd_table), term(:Item, dd_id))),
              1,
              ""
            )

            add_map = CreateNode({ "VALUE" => "" })
            if add_map != {}
              IsnsServer.addDDMember(
                @address,
                dd_id,
                Ops.get_string(add_map, "VALUE", "")
              )
            end

            initDDISCSIMembers(dd_id)
        end
      end

      nil
    end

    def checkISNS
      isns_status = IsnsServer.testISNSAccess(@address)
      if isns_status != "OK"
        #       boolean display = true;
        #       Report::DisplayErrors(display,10);
        Report.Error(
          _("Unable to connect to iSNS server. Check iSNS server address.")
        )
        return 1
      end

      0
    end
  end
end
