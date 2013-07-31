# encoding: utf-8

# File:	include/isns-server/helps.ycp
# Package:	Configuration of isns-server
# Summary:	Help texts of all the dialogs
# Authors:
#
# $Id: helps.ycp 35355 2007-01-15 15:06:49Z mzugec $
module Yast
  module IsnsHelpsInclude
    def initialize_isns_helps(include_target)
      textdomain "isns"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"                => _(
          "<p><b><big>Initializing iSNS daemon configuration</big></b><br>\n</p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"               => _(
          "<p><b><big>Saving iSNS Configuration</big></b><br>\n</p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        # Summary dialog help 1/3
        "summary"             => _(
          "<p><b><big>iSNS Configuration</big></b><br>\nConfigure an iSNS server.<br></p>\n"
        ),
        "ipaddress"           => _(
          "<b><big>iSNS Server location</big></b><br>The DNS name or the IP address of the iSNS service can be entered as the iSNS address.\n"
        ),
        "iscsi_display"       => _(
          "<p>The list of all available iSCSI nodes registered with the iSNS service are displayed.</p> <p>Nodes are registered by iSCSI initiators and iSCSI targets.</p> <p> It is only possible to <b>delete</b> them.  Deleting a node removes it from the iSNS database.</p>"
        ),
        # discovery domains
        "dd_display"          => _(
          "A list of all discovery domains is displayed. It is possible to <b>Create</b> a discovery domain or <b>Delete</b> one. <p>Deleting a domain removes the members from the domain but does not delete the iSCSI node members.</p>"
        ),
        "dd_display_members"  => _(
          "A list of all iSCSI nodes are displayed by discovery domain.  Selecting another discovery domain refreshes the list with members from that discovery domain.  It is possible to <b>Add</b> an iSCSI node to a discovery domain or <b>Delete</b> the node.  <p>Deleting a node removes it from the domain but does not delete the iSCSI node</p> <p>Creating an iSCSI node allows a not yet registered node to be added as a member of the discovery domain.  When the initiator or target registers this node then it becomes part of this domain</p>  <p>When an iSCSI initiator does a discovery request, the iSNS service returns all iSCSI node targets that are members of the same Discovery Domains.</p> "
        ),
        # dds table dialog
        "dds_display"         => _(
          "At the top a list of all Discovery Domain Sets are displayed.  Discovery Domains belong to Discovery Domain Sets. <p>A Discovery Domain must be a member of a Discovery Domain Set in order to be active. </p><p>In an iSNS database, a Discovery Domain Set contains Discovery Domains and Discovery Domains contain iSCSI Node members.</p>"
        ),
        "dds_display_members" => _(
          "<p>The discovery domain set members list is refreshed whenever a different discovery domain set is selected.</p>"
        )
      } 

      # EOF
    end
  end
end
