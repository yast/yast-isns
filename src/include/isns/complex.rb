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

    # Actions to perform when aborting
    #
    # @note The socket is stopped if the process is going to be aborted
    #   and it was not active when the process started.
    #
    # @return [Boolean] true if it should abort; false otherwise
    def abort_configuration
      abort_config = abort?

      if abort_config && !IsnsServer.socket_initially_active?
        IsnsServer.isnsdSocketStop
      end

      abort_config
    end

    # Shows a confirmation popup when something has been edited
    #
    # @return [Boolean] true if it should abort; false otherwise
    def abort?
      !IsnsServer.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    #
    # @return [Symbol] :abort when settings could not be read; :next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))

      return :abort unless IsnsServer.Read

      # Service widget lazy load initialization, since it needs the "open-isns" package which might be
      # installed by IsnsServer.Read if is not available
      load_service_widget

      :next
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
