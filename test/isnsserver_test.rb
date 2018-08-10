#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "spec_helper"

Yast.import "IsnsServer"

describe "Yast::IsnsServer" do
  describe ".Write" do
    subject(:isns_server) { Yast::IsnsServerClass.new }

    before do
      # allow(Yast::Progress).to receive(:New)
      # allow(Yast::Progress).to receive(:NextStage)

      allow(Y2Firewall::Firewalld).to receive(:instance).and_return(firewalld)
      # allow(Yast::Builtins).to receive(:sleep)

      allow(Yast2::SystemService).to receive(:find).with("isnsd").and_return(service)

      allow(Yast::Mode).to receive(:auto) { auto }
      allow(Yast::Mode).to receive(:commandline) { commandline }

      # allow(isns_server).to receive(:PollAbort).and_return(false)
      # allow(isns_server).to receive(:WriteSettings).and_return(true)
      # allow(isns_server).to receive(:write_daemon)

      isns_server.main
    end

    let(:service) { instance_double(Yast2::SystemService, save: true) }

    let(:firewalld) { instance_double(Y2Firewall::Firewalld, write: true) }

    let(:auto) { false }
    let(:commandline) { false }

    shared_examples "old behavior" do
      it "does not save the system service" do
        allow(isns_server).to receive(:setServiceStatus)

        expect(service).to_not receive(:save)

        isns_server.Write
      end

      it "calls to :setServiceStatus" do
        expect(isns_server).to receive(:setServiceStatus)

        isns_server.Write
      end

      context "and the action is correctly performed" do
        before do
          allow(isns_server).to receive(:setServiceStatus).and_return(true)
        end

        it "returns true" do
          expect(isns_server.Write).to eq(true)
        end
      end

      context "and the action is not correctly performed" do
        before do
          allow(isns_server).to receive(:setServiceStatus).and_return(false)
        end

        it "returns false" do
          expect(isns_server.Write).to eq(false)
        end
      end
    end

    context "when running in command line" do
      let(:commandline) { true }

      include_examples "old behavior"
    end

    context "when running in AutoYaST mode" do
      let(:auto) { true }

      include_examples "old behavior"
    end

    context "when running in normal mode" do
      before do
        allow(isns_server).to receive(:socket_initially_active?).and_return(socket_active)
        allow(isns_server).to receive(:isnsdSocketStop)
      end

      let(:socket_active) { false }

      it "does not call to :setServiceStatus" do
        expect(isns_server).to_not receive(:setServiceStatus)

        isns_server.Write
      end

      it "saves the system service" do
        expect(service).to receive(:save)

        isns_server.Write
      end

      context "and the service is correctly saved" do
        before do
          allow(service).to receive(:save).and_return(true)
        end

        it "returns true" do
          expect(isns_server.Write).to eq(true)
        end
      end

      context "and the service is not correctly saved" do
        before do
          allow(service).to receive(:save).and_return(false)
        end

        it "returns false" do
          expect(isns_server.Write).to eq(false)
        end
      end

      context "and the socket was already active" do
        let(:socket_active) { true }

        it "does not try to stop the socket before saving the service" do
          expect(isns_server).to_not receive(:isnsdSocketStop)

          isns_server.Write
        end
      end

      context "and the socket was not active" do
        let(:socket_active) { false }

        it "tries to stop the socket before saving the service" do
          expect(isns_server).to receive(:isnsdSocketStop).ordered
          expect(service).to receive(:save).ordered

          isns_server.Write
        end
      end
    end
  end
end
