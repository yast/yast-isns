# encoding: utf-8

# File:	modules/IsnsServer.ycp
# Package:	Configuration of isns-server
# Summary:	IsnsServer settings, input and output functions
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id: IsnsServer.ycp 35355 2007-01-15 15:06:49Z mzugec $
#
# Representation of the configuration of iscsi-server.
# Input and output routines.
require "yast"
require "yast2/system_service"
require "y2firewall/firewalld"
require "yast2/systemd/socket"

module Yast
  class IsnsServerClass < Module

    def main
      textdomain "isns"

      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Service"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Confirm"
      Yast.import "Mode"
      Yast.import "String"
      Yast.import "Map"

      @serviceStatus = false
      @statusOnStart = false

      # Data was modified?
      @modified = false
      @configured = false

      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")

      @isnsd_socket = nil
    end

    # Service to configure
    #
    # @return [Yast2::SystemService]
    def service
      @service ||= Yast2::SystemService.find("isnsd")
    end

    def isnsdSocketActive?
      if @isnsd_socket
        @isnsd_socket.active?
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketStart
      if @isnsd_socket
        @isnsd_socket.start
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketStop
      if @isnsd_socket
        @isnsd_socket.stop
     else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketEnabled?
      if @isnsd_socket
        @isnsd_socket.enabled?
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketDisabled?
      if @isnsd_socket
        @isnsd_socket.disabled?
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketEnable
      if @isnsd_socket
        @isnsd_socket.enable
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    def isnsdSocketDisable
      if @isnsd_socket
        @isnsd_socket.disable
      else
        log.error("isnsd.socket not found")
        false
      end
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      y2debug("modified=%1", @modified)
      @modified
    end

    # read configuration file /etc/ietd.conf
    def readConfig
      read_values = Convert.convert(
        SCR.Read(path(".etc.isns.all")),
        :from => "any",
        :to   => "map <string, any>"
      )
      # IsnsServerFunctions::parseConfig( read_values );
      y2milestone("isns readConfig")
      true
    end

    # test if required package ("open-isns") is installed
    def installed_packages
      ret = false
      y2milestone("Check if open-isns is installed")
      if !Package.InstallMsg(
          "open-isns",
          _(
            "<p>To configure the isns service, the <b>%1</b> package must be installed.</p>"
          ) +
            _("<p>Install it now?</p>")
        )
        Popup.Error(Message.CannotContinueWithoutPackagesInstalled)
      else
        ret = true
      end

      ret
    end

    # check status of isns service
    # if not enabled, start it manually
    def getServiceStatus
      ret = true

      # start service in stage initial (important for AutoYasT)
      if Stage.initial
        ret = Service.Start("isnsd")
        if ret
          log.info("Service isnsd started")
        else
          log.error("Cannot start service isnsd")
        end
        return ret
      end

      # start socket in installed system
      @isnsd_socket = Yast2::Systemd::Socket.find!("isnsd")

      if isnsdSocketActive?
        @statusOnStart = true
        @serviceStatus = true
      end
      y2milestone("Service status = %1", @statusOnStart)
      isnsdSocketStart if !@statusOnStart
      ret
    end

    # set service status
    def setServiceStatus
      start = true
      start = @statusOnStart if !@serviceStatus

      if !start
        y2milestone("Stop isnsd service and socket")
        isnsdSocketStop
        Service.Stop("isnsd")
      else
        y2milestone("Start isnsd socket")
        Service.Stop("isnsd") if Service.Status("isnsd") == 0
        @serviceStatus = true
        isnsdSocketStart
      end
      true
    end

    def testISNSAccess()
      # We cannot proceed if we are not control node
      isnsadm_control
    end

    def readISCSI
      values = []

      isnsadm_list("nodes").each do |obj|
        temp = {}
        temp["NODE"] = obj["iSCSI name"]
        temp["TYPE"] = obj["iSCSI node type"]
        values.push(temp)
      end

      values
    end

    def readDDMembers(id)
      values = []
      temp = {}

      y2milestone("readDDMembers of DD #{id}")

      ddmembers = isnsadm_query("dd-id=#{id}")["DD member iSCSI name"]
      return [] unless ddmembers

      ddmembers.each do |iqn|
        type = isnsadm_query("iscsi-name=#{iqn}")["iSCSI node type"]
        values << {"NODE" => iqn, "TYPE" => type }
      end

      values
    end

    def readDD
      y2milestone("readDD")
      isnsadm_list("dds")
    end

    def addDDMember(dd_id, iqn)
      y2milestone("addDDMember #{iqn} to #{dd_id}")
      isnsadm("--dd-register dd-id=#{dd_id} dd-member-name=#{iqn}")
    end

    def addDD(iqn)
      y2milestone("addDD #{iqn}")
      isnsadm("--dd-register dd-name=#{iqn}")
    end

    def deleteISCSI(id)
      y2milestone("deleteISCSI: #{id}")
      isnsadm("--deregister iscsi-name=#{id}")
    end

    def deleteDDMember(dd_id, iqn)
      y2milestone("deleteDDMember #{iqn} from #{dd_id}")
      isnsadm("--dd-deregister #{dd_id} dd-member-name=#{iqn}")
    end

    def deleteDD(id)
      y2milestone("deleteDD: #{id}")
      isnsadm("--dd-deregister #{id}")
    end

    # Read all iscsi-server settings
    # @return true on success
    def Read
      # IsnsServer read dialog caption
      caption = _("Initializing isns daemon configuration")

      # check if user is root
      return false if !Confirm.MustBeRoot

      # check if required packages ("open-isns") is installed
      return false if !installed_packages

      # get status of isns init script
      return false if !getServiceStatus

      # detect devices
      Y2Firewall::Firewalld.instance.read

      @modified = false
      @configured = true
      true
    end

    # Write all iscsi-server settings
    #
    # @return [Boolean] true on success; false otherwise
    def Write
      # IsnsServer write dialog caption
      caption = _("Saving isns Configuration")

      Y2Firewall::Firewalld.instance.write

      if Mode.auto || Mode.commandline
        # starts/stops the service (and its socket) according to configuration
        setServiceStatus
      else
        isnsdSocketStop unless socket_initially_active?
        service.save
      end
    end

    # Whether the socket was intially active
    #
    # This module requires to activate the socket to configure the service properly.
    # When the module is launched (see Read), the socket is activated if it was stopped.
    # This method checks if the socket was already active at the beginning of the process.
    #
    # @return [Boolean]
    def socket_initially_active?
      @statusOnStart
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # TODO FIXME: your code here...
      { "install" => [], "remove" => [] }
    end

    # @deprecated
    #
    # get/set service accessors for CWMService component
    def GetStartService
      status = isnsdSocketEnabled?
      y2milestone("isns service status %1", status)
      status
    end

    # @deprecated
    def SetStartService(status)
      y2milestone("Set service status %1", status)
      @serviceStatus = status
      if status == true
        isnsdSocketEnable
      else
        isnsdSocketDisable
      end

      nil
    end

    private

    def isnsadm(params, ret_result = false)
      command = "isnsadm --local #{params}"
      y2debug("Executing #{command}")
      res = SCR.Execute(path(".target.bash_output"), command, {})

      if ret_result
        return res
      else
        return res["exit"] == 0
      end
    end

    def isnsadm_control
      if !@isctrlnode
        res = isnsadm("--register control", true)
        @isctrlnode = res["exit"] == 0

        if !@isctrlnode
          y2error("Registering as control node failed: #{res["stderr"]}; #{res["stdout"]}")
        end
      end

      @isctrlnode
    end

    def isnsadm_query(query)
      if !isnsadm_control
        y2error("We aren't control node. Only default DD shown.")
      end

      stdout = isnsadm("--query #{query}", true)["stdout"]

      parse_obj(stdout)
    end

    def isnsadm_list(type)
      if !isnsadm_control
        y2error("We aren't control node. Only default DD shown.")
      end

      objects = isnsadm("--list #{type}", true)["stdout"].split(/Object \d+:\n/)

      temp = []
      objects.each do |obj|
        next if obj.empty?
        temp << parse_obj(obj)
      end
      temp
    end

    def parse_obj(text)
      obj_details = {}

      text.each_line do |line|
        line.chomp!

        # Schema of each line is:
        # <definition> : <key> = <value>
        # e.g.:
        #  0020  string      : iSCSI name = "iqn.2005-01.org.open-iscsi.foo:disk1"
        #  (   m[1]   )        (  m[2]  )   (                m[3]                )
        #
        # Quotation marks around the value(if any) are stripped.
        # In some cases (dds) keys are not unique.

        line.match(/^\s*(.*)\b\s*:\s*(.*)\b\s*=\s*"*([^"]*)"*\s*$/) do |m|
          key = m[2]
          value = m[3]

          if key == "DD member iSCSI index" || key == "DD member iSCSI name"
            obj_details[key] ||= []
            obj_details[key] << value
          else
            obj_details[key] = value
          end
        end
      end

      obj_details
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :configured, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :readConfig, :type => "boolean ()"
    publish :function => :testISNSAccess, :type => "boolean ()"
    publish :function => :readISCSI, :type => "list <map <string, any>> (string)"
    publish :function => :readDDMembers, :type => "list <map <string, any>> (string, string)"
    publish :function => :readDD, :type => "list <string> (string)"
    publish :function => :addDDMember, :type => "boolean (string, string, string)"
    publish :function => :addDD, :type => "boolean (string, string)"
    publish :function => :deleteISCSI, :type => "boolean (string, string)"
    publish :function => :deleteDDMember, :type => "boolean (string, string, string)"
    publish :function => :deleteDD, :type => "boolean (string, string)"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :AutoPackages, :type => "map ()"
    publish :function => :GetStartService, :type => "boolean ()"
    publish :function => :SetStartService, :type => "void (boolean)"
  end

  IsnsServer = IsnsServerClass.new
  IsnsServer.main
end
