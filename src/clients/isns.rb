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
  class IsnsClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of isns</h3>

      textdomain "isns"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("IsnsServer module started")

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"

      Yast.import "CommandLine"
      Yast.include self, "isns/wizards.rb"

      @cmdline_description = {
        "id"         => "isns",
        # Command line help text for the Xisns module
        "help"       => _(
          "Configuration of an isns service"
        ),
        "guihandler" => fun_ref(method(:IsnsServerSequence), "any ()"),
        "initialize" => fun_ref(IsnsServer.method(:Read), "boolean ()"),
        "finish"     => fun_ref(IsnsServer.method(:Write), "boolean ()"),
        "actions" =>
          # FIXME TODO: fill the functionality description here
          {},
        "options" =>
          # FIXME TODO: fill the option descriptions here
          {},
        "mappings" =>
          # FIXME TODO: fill the mappings of actions and options here
          {}
      }

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      if @propose
        @ret = IsnsServerAutoSequence()
      else
        @ret = CommandLine.Run(@cmdline_description)
      end
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("IsnsServer module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::IsnsClient.new.main
