# encoding: utf-8

# File:	include/isns-server/wizards.ycp
# Package:	Configuration of isns-server
# Summary:	Wizards definitions
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: wizards.ycp 35355 2007-01-15 15:06:49Z mzugec $
module Yast
  module IsnsWizardsInclude
    def initialize_isns_wizards(include_target)
      Yast.import "UI"

      textdomain "isns"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "isns/complex.rb"
      Yast.include include_target, "isns/dialogs.rb"
    end

    # Main workflow of the isns-server configuration
    # @return sequence result
    def MainSequence
      # FIXME: adapt to your needs
      aliases = { "summary" => lambda { SummaryDialog() } }

      # FIXME: adapt to your needs
      sequence = {
        "ws_start" => "summary",
        "summary"  => { :abort => :abort, :next => :next }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of isns-server
    # @return sequence result
    def IsnsServerSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("org.opensuse.yast.iSNS")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of isns-server but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def IsnsServerAutoSequence
      # Initialization dialog caption
      caption = _("isns Daemon Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
