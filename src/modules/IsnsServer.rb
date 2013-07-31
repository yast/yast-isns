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

module Yast
  class IsnsServerClass < Module
    def main
      textdomain "isns"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Service"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "SuSEFirewall"
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
      Builtins.y2debug("modified=%1", @modified)
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
      Builtins.y2milestone("isns readConfig")
      true
    end

    # write configuration file /etc/ietd.conf
    def writeConfig
      # prepare map, because perl->ycp lost information about data types (integers in this case)
      # map <string, any> config_file = IsnsServerFunctions::writeConfig();
      # config_file["type"]=tointeger(config_file["type"]:"1");
      # config_file["file"]=tointeger(config_file["file"]:"1");
      # list <map<string, any> > value = [];
      # foreach(map<string, any> row, config_file["value"]:[], {
      #  row["type"]=tointeger(row["type"]:"1");
      #  row["file"]=tointeger(row["file"]:"1");
      #  value = add(value, row);
      # });
      #
      # config_file["value"] = value;
      # y2milestone("config_file to write %1", config_file);
      # // write it
      # SCR::Write(.etc.ietd.all, config_file);
      # SCR::Write(.etc.ietd, nil);
      true
    end



    # test if required package ("isns") is installed
    def installed_packages
      ret = false
      Builtins.y2milestone("Check if isns is installed")
      if !Package.InstallMsg(
          "isns",
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
      if Service.Status("isns") == 0
        @statusOnStart = true
        @serviceStatus = true
      end
      Builtins.y2milestone("Service status = %1", @statusOnStart)
      Service.Start("isns") if !@statusOnStart
      ret
    end

    # set service status
    def setServiceStatus
      start = true
      start = @statusOnStart if !@serviceStatus

      if !start
        Builtins.y2milestone("Stop isns service")
        Service.Stop("isns")
      else
        Builtins.y2milestone("Start isns service")
        @serviceStatus = true
        Service.Start("isns")
      end
      true
    end

    def testISNSAccess(address)
      value = "OK"
      temp = {}

      command = Builtins.sformat("isnsadm -a %1 -t -q iscsi", address)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        if row == "TCP error on connection"
          Builtins.y2milestone("TCP error: %1 ", row)
          value = "ERROR"
        end
        if row == "Error Sending TCP request."
          Builtins.y2milestone("Failed to resolve host error: %1 ", row)
          value = "ERROR"
        end
      end

      value
    end
    def readISCSI(address)
      values = []
      temp = {}

      command = Builtins.sformat("isnsadm -a %1 -t -q iscsi", address)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
        end
        if key == "iSCSI ID  "
          val = Builtins.substring(row, Ops.add(pos, 2))
          Ops.set(temp, "NODE", val)
        end
        if key == "Type"
          val = Builtins.substring(row, Ops.add(pos, 6))
          Ops.set(temp, "TYPE", val)
          values = Builtins.add(values, temp)
        end
      end

      deep_copy(values)
    end

    def readISCSI_type(address, index)
      temp = ""

      Builtins.y2milestone("iSCSIRead_type index:%1", index)

      command = Builtins.sformat(
        "isnsadm -a %1 -t -q iscsi -n %2",
        address,
        index
      )
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
          val = Builtins.substring(row, Ops.add(pos, 6))
        end
        Builtins.y2milestone("iSCSIRead_type %1", key)
        if key == "Type"
          Builtins.y2milestone("iSCSIRead_type return value is %1", val)
          temp = val
        end
      end

      temp
    end


    def readDDS(address)
      values = []
      ddid = ""

      Builtins.y2milestone("readDDS %1", address)
      command = Builtins.sformat("isnsadm -a %1 -t -q dds", address)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
          val = Builtins.substring(row, Ops.add(pos, 2))
        end
        if key == "DDS ID  "
          values = Builtins.add(values, val)
        elsif key == "DDS Sym Name "
          values = Builtins.add(values, val)
        end
      end

      deep_copy(values)
    end

    def readDDMembers(address, id)
      values = []
      temp = {}
      ddid = ""

      Builtins.y2milestone("readDDSMembers %1 %2", address, id)
      command = Builtins.sformat("isnsadm -a %1 -t -q dd -n %2", address, id)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        Builtins.y2milestone("results: %1", row)
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
          val = Builtins.substring(row, Ops.add(pos, 2))
        end
        Ops.set(temp, "NODE", val) if key == "   DD iSCSI Member "
        if key == "   DD iSCSI Member Index  "
          Ops.set(temp, "TYPE", readISCSI_type(address, val))
          values = Builtins.add(values, temp)
        end
      end

      deep_copy(values)
    end

    def readDDSMembers(address, id)
      values = []
      ddid = ""

      Builtins.y2milestone("readDDSMembers %1 %2", address, id)
      command = Builtins.sformat("isnsadm -a %1 -t -q dds -n %2", address, id)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        Builtins.y2milestone("results: %1", row)
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
          val = Builtins.substring(row, Ops.add(pos, 2))
        end
        if key == "   DD ID "
          values = Builtins.add(values, val)
        elsif key == "   DD Sym Name "
          values = Builtins.add(values, val)
        end
      end

      deep_copy(values)
    end

    def readDD(address)
      values = []
      ddid = ""

      Builtins.y2milestone("readDD")
      command = Builtins.sformat("isnsadm -a %1 -t -q dd", address)
      result = Convert.convert(
        SCR.Execute(path(".target.bash_output"), command, {}),
        :from => "any",
        :to   => "map <string, any>"
      )
      Builtins.foreach(
        Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n")
      ) do |row|
        pos = Builtins.findfirstof(row, ":")
        key = ""
        val = ""
        if pos != nil && Ops.greater_than(pos, 0)
          key = Builtins.substring(row, 0, pos)
          val = Builtins.substring(row, Ops.add(pos, 2))
        end
        if key == "DD ID  "
          values = Builtins.add(values, val)
        elsif key == "DD Sym Name "
          values = Builtins.add(values, val)
        end
      end

      deep_copy(values)
    end

    def addISCSI(address, name, entityid)
      Builtins.y2milestone("addDDS")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -r iscsi -n '%2' -m '%3'",
        address,
        name,
        entityid
      )
      SCR.Execute(path(".target.bash_output"), command, {})
      true
    end

    def addDDS(address, name)
      Builtins.y2milestone("addDDS")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -r dds -n '%2'",
        address,
        name
      )
      SCR.Execute(path(".target.bash_output"), command, {})
      true
    end

    def addDDMember(address, dd_id, iqn)
      Builtins.y2milestone("addDDMember")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -r ddmember -n %2 -m %3",
        address,
        dd_id,
        iqn
      )
      SCR.Execute(path(".target.bash_output"), command, {})
      true
    end

    def addDDSMember(address, dds_id, dd_id)
      Builtins.y2milestone("addDDSMember")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -r ddsmember -n %2 -m %3",
        address,
        dds_id,
        dd_id
      )
      SCR.Execute(path(".target.bash_output"), command, {})
      true
    end

    def addDD(address, name)
      Builtins.y2milestone("addDD")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -r dd -n '%2'",
        address,
        name
      )
      SCR.Execute(path(".target.bash_output"), command, {})
      true
    end

    def deleteISCSI(address, id)
      Builtins.y2milestone("deleteISCSI")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -d iscsi -n '%2'",
        address,
        id
      )
      SCR.Execute(path(".target.bash_output"), command, {})

      true
    end

    def deleteDDS(address, id)
      Builtins.y2milestone("deleteDDS")
      command = Builtins.sformat("isnsadm -a %1 -t -d dds -n '%2'", address, id)
      SCR.Execute(path(".target.bash_output"), command, {})

      true
    end

    def deleteDDMember(address, dd_id, iqn)
      Builtins.y2milestone("deleteDDSMember:%1", iqn)
      command = Builtins.sformat(
        "isnsadm -a %1 -t -d ddmember -n %2 -m %3",
        address,
        dd_id,
        iqn
      )
      SCR.Execute(path(".target.bash_output"), command, {})

      true
    end

    def deleteDDSMember(address, dds_id, dd_id)
      Builtins.y2milestone("deleteDDSMember")
      command = Builtins.sformat(
        "isnsadm -a %1 -t -d ddsmember -n %2 -m %3",
        address,
        dds_id,
        dd_id
      )
      SCR.Execute(path(".target.bash_output"), command, {})

      true
    end

    def deleteDD(address, id)
      Builtins.y2milestone("deleteDDS")
      command = Builtins.sformat("isnsadm -a %1 -t -d dd -n '%2'", address, id)
      SCR.Execute(path(".target.bash_output"), command, {})

      true
    end


    # Read all iscsi-server settings
    # @return true on success
    def Read
      # IsnsServer read dialog caption
      caption = _("Initializing isns daemon configuration")

      # TODO FIXME Set the right number of stages
      steps = 4

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          _("Read the database"),
          # Progress stage 2/3
          _("Read the previous settings"),
          # Progress stage 3/3
          _("Detect the devices")
        ],
        [
          # Progress step 1/3
          _("Reading the database..."),
          # Progress step 2/3
          _("Reading the previous settings..."),
          # Progress step 3/3
          _("Detecting the devices..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # check if user is root
      return false if !Confirm.MustBeRoot
      Progress.NextStage
      # check if required packages ("isns") is installed
      return false if !installed_packages
      Builtins.sleep(sl)

      return false if Abort()
      Progress.NextStep
      # get status of isns init script
      return false if !getServiceStatus
      Builtins.sleep(sl)

      return false if Abort()
      Progress.NextStage
      # read configuration (/etc/ietd.conf)
      if !readConfig
        Report.Error(Message.CannotReadCurrentSettings)
        return false
      end
      Builtins.sleep(sl)

      # detect devices
      Progress.set(false)
      SuSEFirewall.Read
      Progress.set(true)

      Progress.NextStage
      # Error message
      return false if false
      Builtins.sleep(sl)

      return false if Abort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)

      return false if Abort()
      @modified = false
      @configured = true
      true
    end

    # Write all iscsi-server settings
    # @return true on success
    def Write
      # IsnsServer write dialog caption
      caption = _("Saving isns Configuration")

      # TODO FIXME And set the right number of stages
      steps = 2

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/2
          _("Run SuSEconfig")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/2
          _("Running SuSEconfig..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )


      Progress.set(false)
      SuSEFirewall.Write
      Progress.set(true)

      Progress.NextStage
      # write configuration (/etc/isns.conf)
      Report.Error(_("Cannot write settings.")) if !writeConfig
      Builtins.sleep(sl)


      return false if Abort()
      Progress.NextStage
      #  ask user whether reload or restart server and do it
      #    if ( (serviceStatus) || (statusOnStart) )
      #	if (!reloadServer()) return false;
      #    sleep(sl);

      return false if Abort()
      Progress.NextStage
      Builtins.sleep(sl)

      # set isns initscript status
      return false if !setServiceStatus
      true
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # TODO FIXME: your code here...
      { "install" => [], "remove" => [] }
    end


    # get/set service accessors for CWMService component
    def GetStartService
      status = Service.Enabled("isns")
      Builtins.y2milestone("isns service status %1", status)
      status
    end

    def SetStartService(status)
      Builtins.y2milestone("Set service status %1", status)
      @serviceStatus = status
      if status == true
        Service.Enable("isns")
      else
        Service.Disable("isns")
      end

      nil
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :configured, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :readConfig, :type => "boolean ()"
    publish :function => :testISNSAccess, :type => "string (string)"
    publish :function => :readISCSI, :type => "list <map <string, any>> (string)"
    publish :function => :readISCSI_type, :type => "string (string, string)"
    publish :function => :readDDS, :type => "list <string> (string)"
    publish :function => :readDDMembers, :type => "list <map <string, any>> (string, string)"
    publish :function => :readDDSMembers, :type => "list <string> (string, string)"
    publish :function => :readDD, :type => "list <string> (string)"
    publish :function => :addISCSI, :type => "boolean (string, string, string)"
    publish :function => :addDDS, :type => "boolean (string, string)"
    publish :function => :addDDMember, :type => "boolean (string, string, string)"
    publish :function => :addDDSMember, :type => "boolean (string, string, string)"
    publish :function => :addDD, :type => "boolean (string, string)"
    publish :function => :deleteISCSI, :type => "boolean (string, string)"
    publish :function => :deleteDDS, :type => "boolean (string, string)"
    publish :function => :deleteDDMember, :type => "boolean (string, string, string)"
    publish :function => :deleteDDSMember, :type => "boolean (string, string, string)"
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
