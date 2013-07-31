# encoding: utf-8

# File:
#  isns_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Michal Zugec <mzugec@suse.cz>
#
module Yast
  class IsnsFinishClient < Client
    def main
      Yast.import "UI"

      textdomain "isns"

      Yast.import "Directory"
      Yast.include self, "installation/misc.rb"

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

      Builtins.y2milestone("starting scsi-client_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        return {
          "steps" => 1,
          # progress step title
          "title" => _("Saving iSCSI configuration..."),
          "when"  => [:installation, :update, :autoinst]
        }
      elsif @func == "Write"
        # write isns database of automatic connected targets
        WFM.Execute(
          path(".local.bash"),
          Ops.add(
            Ops.add(
              "test -d /var/lib/isns/ && /bin/cp -a /var/lib/isns/* ",
              Installation.destdir
            ),
            "/var/lib/isns/"
          )
        )
        WFM.Execute(
          path(".local.bash"),
          Ops.add(
            Ops.add(
              "test -d /etc/isns/ && /bin/cp -a /etc/isns/* ",
              Installation.destdir
            ),
            "/etc/isns/"
          )
        )
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("isns_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::IsnsFinishClient.new.main
