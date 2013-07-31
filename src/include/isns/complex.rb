# encoding: utf-8

# File:	include/isns-server/complex.ycp
# Package:	Configuration of isns-server
# Summary:	Dialogs definitions
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: complex.ycp 27936 2006-02-13 20:01:14Z olh $
module Yast
  module IsnsComplexInclude
    def initialize_isns_complex(include_target)
      Yast.import "UI"

      textdomain "isns"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "IsnsServer"

      Yast.include include_target, "isns/helps.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      IsnsServer.Modified
    end

    def ReallyAbort
      !IsnsServer.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      # IsnsServer::AbortFunction = PollAbort;
      ret = IsnsServer.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      # IsnsServer::AbortFunction = PollAbort;
      ret = IsnsServer.Write
      ret ? :next : :abort
    end
  end
end
