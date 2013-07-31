# encoding: utf-8

# File:	clients/isns_auto.ycp
# Package:	Configuration of isns
# Summary:	Client for autoinstallation
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: isns_auto.ycp 35560 2007-01-22 08:02:23Z mzugec $
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of isns settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("isns_auto", [ "Summary", mm ]);
module Yast
  class IsnsAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "isns"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("IsnsServer auto started")

      Yast.import "IsnsServer"
      Yast.include self, "isns/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      # if(func == "Summary") {
      #     ret = select(IsnsServer::Summary(), 0, "");
      # }
      # Reset configuration
      #else
      # if (func == "Reset") {
      #     IsnsServer::Import($[]);
      #     ret = $[];
      # }
      # Change configuration (run AutoSequence)
      #else
      if @func == "Change"
        @ret = IsnsServerAutoSequence()
      # Import configuration
      # else if (func == "Import") {
      #     ret = IsnsServer::Import(param);
      # }
      # Return actual state
      # else if (func == "Export") {
      #     ret = IsnsServer::Export();
      # }
      # Return needed packages
      elsif @func == "Packages"
        @ret = IsnsServer.AutoPackages
      elsif @func == "GetModified"
        @ret = IsnsServer.modified
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        @ret = IsnsServer.Read
        Progress.set(@progress_orig)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        IsnsServer.write_only = true
        @ret = IsnsServer.Write
        Progress.set(@progress_orig)
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("IsnsServer auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::IsnsAutoClient.new.main
