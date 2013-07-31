# encoding: utf-8

# File:	clients/isns_proposal.ycp
# Package:	Configuration of isns-client
# Summary:	Proposal function dispatcher.
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: isns_proposal.ycp 28596 2006-03-06 11:28:57Z mzugec $
#
# Proposal function dispatcher for isns configuration.
# See source/installation/proposal/proposal-API.txt
module Yast
  class IsnsProposalClient < Client
    def main

      textdomain "isns"

      Yast.import "IsnsServer"
      Yast.import "Progress"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("IsnsServer proposal started")

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset || !IsnsServer.proposal_valid
          IsnsServer.proposal_valid = true
          @progress_orig = Progress.set(false)
          IsnsServer.Read
          Progress.set(@progress_orig)
        end 
        #     list sum = IsnsServer::Summary();
        #     proposal = sum[0]:"";
        #
        #     ret = $[
        # 	"preformatted_proposal" : proposal,
        # 	"warning_level" : warning_level,
        # 	"warning" : warning,
        #     ];
      # run the module
      # else if(func == "AskUser") {
      #     map stored = IsnsServer::Export();
      #     symbol seq = (symbol) WFM::CallFunction("isns", [.propose]);
      #     if(seq != `next) IsnsServer::Import(stored);
      #     y2debug("stored=%1",stored);
      #     y2debug("seq=%1",seq);
      #     ret = $[
      # 	"workflow_sequence" : seq
      #     ];
      # }
      # create titles
      elsif @func == "Description"
        @ret = {
          # Rich text title for IsnsServer in proposals
          "rich_text_title" => _(
            "iSCSI Initiator"
          ),
          # Menu title for IsnsServer in proposals
          "menu_title"      => _(
            "&iSCSI Initiator"
          ),
          "id"              => "isns"
        }
      # write the proposal
      elsif @func == "Write"
        IsnsServer.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("IsnsServer proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::IsnsProposalClient.new.main
