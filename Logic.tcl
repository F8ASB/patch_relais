###############################################################################
#
# Generic Logic event handlers
#
###############################################################################


#
# This is the namespace in which all functions and variables below will exist.
#
namespace eval Logic {

#
# A global variable for emergency mode
#
variable emergency 0;

#
# A variable used to store a timestamp for the last identification.
#
variable prev_ident 0;

#
# A constant that indicates the minimum time in seconds to wait between two
# identifications. Manual and long identifications is not affected.
#
variable min_time_between_ident 120;

#
# Short and long identification intervals. They are setup from config
# variables below.
#
variable short_ident_interval 0;
variable long_ident_interval 0;

variable short_voice_id_enable  1
variable short_cw_id_enable     0
variable short_announce_enable  0
variable short_announce_file    ""

variable long_voice_id_enable   1
variable long_cw_id_enable      0
variable long_announce_enable   0
variable long_announce_file     ""

#
# The ident_only_after_tx variable indicates if identification is only to
# occur after the node has transmitted. The variable is setup below from the
# configuration variable with the same name.
# The need_ident variable indicates if identification is needed.
#
variable ident_only_after_tx 0;
variable need_ident 0;

#
# List of functions that should be called periodically. Use the
# addMinuteTickSubscriber and addSecondTickSubscriber functions to
# add subscribers.
#
variable minute_tick_subscribers [list];
variable second_tick_subscribers [list];

#
# Contains the ID of the last receiver that indicated squelch activity
#
variable sql_rx_id "?";

proc status_emergency {} {
#global emergency;
#set emergency 0;
variable emergency;
return $emergency;
}


#
# Executed when the SvxLink software is started
#
proc startup {} {
  #playMsg "Core" "online"
  #send_short_ident

}

#
# Executed when a specified module could not be found
#   module_id - The numeric ID of the module
#
proc no_such_module {module_id} {
  playMsg "Core" "no_such_module";
  playNumber $module_id;
}


#
# Executed when a manual identification is initiated with the * DTMF code
#
proc manual_identification {} {
  global mycall;
  global report_ctcss;
  global active_module;
  global loaded_modules;
  variable CFG_TYPE;
  variable prev_ident;

  set epoch [clock seconds];
  set hour [clock format $epoch -format "%k"];
  regexp {([1-5]?\d)$} [clock format $epoch -format "%M"] -> minute;
  set prev_ident $epoch;

  playMsg "Core" "online";
  spellWord $mycall;
  if {$CFG_TYPE == "Repeater"} {
    playMsg "Core" "repeater";
  }
  playSilence 250;
  playMsg "Core" "the_time_is";
  playTime $hour $minute;
  playSilence 250;
  if {$report_ctcss > 0} {
    playMsg "Core" "pl_is";
    playFrequency $report_ctcss
    playSilence 300;
  }
  if {$active_module != ""} {
    playMsg "Core" "active_module";
    playMsg $active_module "name";
    playSilence 250;
    set func "::";
    append func $active_module "::status_report";
    if {"[info procs $func]" ne ""} {
      $func;
    }
  } else {
    foreach module [split $loaded_modules " "] {
      set func "::";
      append func $module "::status_report";
      if {"[info procs $func]" ne ""} {
	$func;
      }
    }
  }
  playMsg "Default" "press_0_for_help"
  playSilence 250;
}


#
# Executed when a short identification should be sent
#   hour    - The hour on which this identification occur
#   minute  - The minute on which this identification occur
#
proc send_short_ident {{hour -1} {minute -1}} {
  global mycall;
  variable CFG_TYPE;
  variable short_announce_file
  variable short_announce_enable
  variable short_voice_id_enable
  variable short_cw_id_enable

  # Play voice id if enabled
  if {$short_voice_id_enable} {
    puts "Playing short voice ID"
#    spellWord $mycall;
    if {$CFG_TYPE == "Repeater"} {
      playMsg $mycall "balisecourte";
     # read_info
      #playMsg "Core" "repeater";
    }
    playSilence 500;
  }

  # Play announcement file if enabled
  if {$short_announce_enable} {
    puts "Playing short announce"
    if [file exist "$short_announce_file"] {
      playFile "$short_announce_file"
      playSilence 500
    }
  }

  # Play CW id if enabled
  if {$short_cw_id_enable} {
    puts "Playing short CW ID"
    if {$CFG_TYPE == "Repeater"} {
      set call "$mycall/R"
      CW::play $call
    } else {
      CW::play $mycall
    }
    playSilence 500;
  }
}


#
# Executed when a long identification (e.g. hourly) should be sent
#   hour    - The hour on which this identification occur
#   minute  - The minute on which this identification occur
#
proc send_long_ident {hour minute} {
  global mycall;
  global loaded_modules;
  global active_module;
  variable CFG_TYPE;
  variable long_announce_file
  variable long_announce_enable
  variable long_voice_id_enable
  variable long_cw_id_enable

  # Play the voice ID if enabled
  if {$long_voice_id_enable} {
#    puts "Playing Long voice ID"
#    spellWord $mycall;
    if {$CFG_TYPE == "Repeater"} {
      #playMsg "Core" "repeater";
   # CoronaInfo
    playMsg $mycall "baliselongue";  
  }
    playSilence 500;
#    playMsg "Core" "the_time_is";
#    playSilence 100;
#    playTime $hour $minute;
#    playSilence 500;

    # Call the "status_report" function in all modules if no module is active
    if {$active_module == ""} {
      foreach module [split $loaded_modules " "] {
        set func "::";
        append func $module "::status_report";
        if {"[info procs $func]" ne ""} {
          $func;
        }
      }
    }

    playSilence 500;
  }

  # Play announcement file if enabled
  if {$long_announce_enable} {
    puts "Playing long announce"
    if [file exist "$long_announce_file"] {
      playFile "$long_announce_file"
      playSilence 500
    }
  }

  # Play CW id if enabled
  if {$long_cw_id_enable} {
    puts "Playing long CW ID"
    if {$CFG_TYPE == "Repeater"} {
      set call "$mycall/R"
      CW::play $call
    } else {
      CW::play $mycall
    }
    playSilence 100
  }
}

#
#Lecture du ou des messages d'information si présents dans le repertoire
#

proc read_info {} {

set repertoire "/usr/share/svxlink/sounds/fr_FR/Messages/"

#liste des fichier wav du répertoire choisi, dans l'ordre alphabétique et donc dans l'ordre de date et heure de début

set repertoire "/usr/share/svxlink/sounds/fr_FR/Messages/"
set repOld "/usr/share/svxlink/sounds/fr_FR/Messages/old/"

set listeFichiers [lsort -ascii [glob -nocomplain -directory $repertoire *.wav]]
puts $listeFichiers

set nbFichiers [llength $listeFichiers]

if { $nbFichiers == 0 } {
    puts "Pas de Fichiers !!!"
} else {

    #Date et heure courantes
    set dhCourante [clock seconds]
    puts [clock format $dhCourante -format "%y%m%d%H%M"]

    foreach nomFichier $listeFichiers {
        #fichier sans son dossier
        set fichierCourt [file tail $nomFichier]

        #extraction des dates et heures
        set dhDebutFichier [string range $fichierCourt 0 9]
        set dhFinFichier [string range $fichierCourt 10 19]
        puts "Début $dhDebutFichier, fin $dhFinFichier"

        #test de validité, puis test de date, et c'est fini
        if { [string is integer -strict $dhDebutFichier] && [string is integer -strict $dhFinFichier] } {
            set dhDeb [clock scan $dhDebutFichier -format "%y%m%d%H%M"]
            set dhFin [clock scan $dhFinFichier -format "%y%m%d%H%M"]
            
            if { $dhCourante > $dhFin } {
                # suppression des vieux fichiers
                if { [file isdirectory $repOld] } {
                    file rename $nomFichier $repOld
                }
            } else { 
                if { $dhCourante >= $dhDeb } {
                    #puts "Check !!, c'est le moment de jouer le fichier $nomFichier" 
                    set racineFichier [file rootname $fichierCourt]
                    puts "Check !!, c'est le moment de jouer le fichier $racineFichier"
                    playMsg "Messages" $racineFichier ;
                }
            }
        } 
    }
}
}



#
# Executed when the squelch have just closed and the RGR_SOUND_DELAY timer has
# expired.
#

proc send_rgr_sound {} {

variable sql_rx_id;

#lecture du signal SMETRE

if { [file exists /mnt/ram/smeter.tcl]  } {
          # source "/usr/share/svxlink/events.d/local/SVXCard/smeter.tcl"
           source "/mnt/ram/smeter.tcl"
           puts $signal
              set son ""
                  if {$signal >=0} {
                        if {$signal>=10} {
                        set son "S9+" ; } else {
                        append son "S" $signal ;
                        }
                  playMsg "SVXCard/SMeter" $son;
                  }
           puts "Signal level on RX ID $sql_rx_id : $son";
       }

  playTone 440 200 100;
#CW::setPitch 600; # Sets the CW Tone to ~750 Hz
#CW::setAmplitude 100;
#CW::setCpm 125
#CW::play "k";

  playSilence 200;
}



#
# Executed when an empty macro command (i.e. D#) has been entered.
#

proc macro_empty {} {
  playMsg "Core" "operation_failed";
}


#
# Executed when an entered macro command could not be found
#
proc macro_not_found {} {
  playMsg "Core" "operation_failed";
}


#
# Executed when a macro syntax error occurs (configuration error).
#
proc macro_syntax_error {} {
  playMsg "Core" "operation_failed";
}


#
# Executed when the specified module in a macro command is not found
# (configuration error).
#
proc macro_module_not_found {} {
  playMsg "Core" "operation_failed";
}


#
# Executed when the activation of the module specified in the macro command
# failed.
#
proc macro_module_activation_failed {} {
  playMsg "Core" "operation_failed";
}


#
# Executed when a macro command is executed that requires a module to
# be activated but another module is already active.
#
proc macro_another_active_module {} {
  global active_module;

  playMsg "Core" "operation_failed";
  playMsg "Core" "active_module";
  playMsg $active_module "name";
}


#
# Executed when an unknown DTMF command is entered
#   cmd - The command string
#
proc unknown_command {cmd} {
  spellWord $cmd;
  playMsg "Core" "unknown_command";
}


#
# Executed when an entered DTMF command failed
#   cmd - The command string
#
proc command_failed {cmd} {
  spellWord $cmd;
  playMsg "Core" "operation_failed";
}


#
# Executed when a link to another logic core is activated.
#   name  - The name of the link
#
proc activating_link {name} {
  if {[string length $name] > 0} {
    playMsg "Core" "activating_link_to";
    spellWord $name;
  }
}


#
# Executed when a link to another logic core is deactivated.
#   name  - The name of the link
#
proc deactivating_link {name} {
  if {[string length $name] > 0} {
    playMsg "Core" "deactivating_link_to";
    spellWord $name;
  }
}


#
# Executed when trying to deactivate a link to another logic core but the
# link is not currently active.
#   name  - The name of the link
#
proc link_not_active {name} {
  if {[string length $name] > 0} {
    playMsg "Core" "link_not_active_to";
    spellWord $name;
  }
}


#
# Executed when trying to activate a link to another logic core but the
# link is already active.
#   name  - The name of the link
#
proc link_already_active {name} {
  if {[string length $name] > 0} {
    playMsg "Core" "link_already_active_to";
    spellWord $name;
  }
}


#
# Executed each time the transmitter is turned on or off
#   is_on - Set to 1 if the transmitter is on or 0 if it's off
#
proc transmit {is_on} {
  #puts "Turning the transmitter $is_on";
  variable prev_ident;
  variable need_ident;
  if {$is_on && ([clock seconds] - $prev_ident > 5)} {
    set need_ident 1;
  }
}


#
# Executed each time the squelch is opened or closed
#   rx_id   - The ID of the RX that the squelch opened/closed on
#   is_open - Set to 1 if the squelch is open or 0 if it's closed
#
proc squelch_open {rx_id is_open} {
  variable sql_rx_id;
#  puts "The squelch is $is_open on RX $rx_id";
  puts "lancement smetre"
  
#  set sql_rx_id $rx_id;
#if {$is_open==0 && [file exists /mnt/ram/smeter.tcl]} {
#file delete -force /mnt/ram/smeter.tcl];
# }
 }


#
# Executed when a DTMF digit has been received
#   digit     - The detected DTMF digit
#   duration  - The duration, in milliseconds, of the digit
#
# Return 1 to hide the digit from further processing in SvxLink or
# return 0 to make SvxLink continue processing as normal.
#
proc dtmf_digit_received {digit duration} {
  #puts "DTMF digit \"$digit\" detected with duration $duration ms";
  return 0;
}


#
# Executed when a DTMF command has been received
#   cmd - The command
#
# Return 1 to hide the command from further processing is SvxLink or
# return 0 to make SvxLink continue processing as normal.
#
# This function can be used to implement your own custom commands or to disable
# DTMF commands that you do not want users to execute.
proc dtmf_cmd_received {cmd} {
  #global active_module

  # Example: Ignore all commands starting with 3 in the EchoLink module.
  #          Allow commands that have four or more digits.
  #if {$active_module == "EchoLink"} {
  #  if {[string length $cmd] < 4 && [string index $cmd 0] == "3"} {
  #    puts "Ignoring random connect command for module EchoLink: $cmd"
  #    return 1
  #  }
  #}

  # Handle the "force core command" mode where a command is forced to be
  # executed by the core command processor instead of by an active module.
  # The "force core command" mode is entered by prefixing a command by a star.
  #if {$active_module != "" && [string index $cmd 0] != "*"} {
  #  return 0
  #}
  #if {[string index $cmd 0] == "*"} {
  #  set cmd [string range $cmd 1 end]
  #}

  # Example: Custom command executed when DTMF 99 is received
  #if {$cmd == "99"} {
  #  puts "Executing external command"
  #  playMsg "Core" "online"
  #  exec ls &
  #  return 1
  #}
variable emergency;

#Mode URGENCE ON code DTMF 181
if {$cmd == "181"} {
    set emergency 1
    puts "Emergency actived status: $emergency"
    playMsg "SVXCard/Emergency" "EmergencyMode"
    playMsg "repeater_commands" "activating"
    playSilence 500
    playMsg "SVXCard" "Emergency/EmergencyBeacon"
    return 1
  }
#Mode URGENCE OFF code DTMF 180
if {$cmd == "180"} {
    set emergency 0
    puts "Emergency desactived status: $emergency"
    playMsg "SVXCard/Emergency" "EmergencyMode"
    playMsg "repeater_commands" "deactivating"
    return 1
  }
# 95 SvxReflector RRF

  if {$cmd == "95"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.default &
    return 1
  }


# 96 SvxReflector RRF

  if {$cmd == "96"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.rrf &
    return 1
  }

# 97 SvxReflector FON

  if {$cmd == "97"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.fon &
    return 1
  }


# 98 Salon Technique
  if {$cmd == "98"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.tec &
    return 1
  }

# 49 Salon International
  if {$cmd == "49"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.ri49 &
    return 1
  }

# 100 Salon Bavardage
  if {$cmd == "100"} {
    puts "Executing external command"
    playMsg "Core" "online"
   exec nohup /etc/svxlink/restart.bav &
    return 1
  }

# 101 Salon Local
  if {$cmd == "101"} {
    puts "Executing external command"
    playMsg "Core" "online"
    exec nohup /etc/svxlink/restart.loc &
    return 1
  }

# 103 Echolink
  if {$cmd == "103"} {
    puts "Executing external command"
    playMsg "Core" "online"    
    exec nohup /etc/svxlink/restart.el &
    return 1
  }
# 104 salon Regional
  if {$cmd == "102"} {
    puts "Executing external command"
    playMsg "Core" "online"    
    exec nohup /etc/svxlink/restart.reg &
    return 1
  }

#La fete du jour
#if {$cmd == "15"} {
#    set datefete [clock format [clock seconds] -format Fetes%d%m ];
#    playMsg "SVXCard/fetes" $datefete;
#    return 1
#  }


  return 0
}


#
# Executed once every whole minute. Don't put any code here directly
# Create a new function and add it to the timer tick subscriber list
# by using the function addMinuteTickSubscriber.
#
proc every_minute {} {
  variable minute_tick_subscribers;
  #puts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"];
  foreach subscriber $minute_tick_subscribers {
    $subscriber;
  }
}


#
# Executed once every whole minute. Don't put any code here directly
# Create a new function and add it to the timer tick subscriber list
# by using the function addSecondTickSubscriber.
#
proc every_second {} {
  variable second_tick_subscribers;
  #puts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"];
  foreach subscriber $second_tick_subscribers {
    $subscriber;
  }
}


#
# Deprecated: Use the addMinuteTickSubscriber function instead
#
proc addTimerTickSubscriber {func} {
  puts "*** WARNING: Calling deprecated TCL event handler addTimerTickSubcriber."
  puts "             Use addMinuteTickSubscriber instead"
  addMinuteTickSubscriber $func;
}


#
# Use this function to add a function to the list of functions that
# should be executed once every whole minute. This is not an event
# function but rather a management function.
#
proc addMinuteTickSubscriber {func} {
  variable minute_tick_subscribers;
  lappend minute_tick_subscribers $func;
}


#
# Use this function to add a function to the list of functions that
# should be executed once every second. This is not an event
# function but rather a management function.
#
proc addSecondTickSubscriber {func} {
  variable second_tick_subscribers;
  lappend second_tick_subscribers $func;
}


#
# Should be executed once every whole minute to check if it is time to
# identify. Not exactly an event function. This function handle the
# identification logic and call the send_short_ident or send_long_ident
# functions when it is time to identify.
#
proc checkPeriodicIdentify {} {
  variable prev_ident;
  variable short_ident_interval;
  variable long_ident_interval;
  variable min_time_between_ident;
  variable ident_only_after_tx;
  variable need_ident;
  global logic_name;

  if {[Logic::status_emergency]} {
    set now [clock seconds];
    set hour [clock format $now -format "%k"];
    regexp {([1-5]?\d)$} [clock format $now -format "%M"] -> minute;

    set emergency_ident_interval  2; #period of emergency beacon (in minutes)
    set emergency_ident_now \
              [expr {($hour * 60 + $minute) % $emergency_ident_interval == 0}];
    puts "$hour $now $minute $emergency_ident_now";

    if { $emergency_ident_now } {
      puts "$logic_name: Sending Emergency identification...";
      playMsg "SVXCard" "Emergency/EmergencyBeacon"
    }

  return;  #Following standard identification no more executed
  }

  if {$short_ident_interval == 0} {
    return;
  }

  set now [clock seconds];
  set hour [clock format $now -format "%k"];
  regexp {([1-5]?\d)$} [clock format $now -format "%M"] -> minute;

  set short_ident_now \
      	    [expr {($hour * 60 + $minute) % $short_ident_interval == 0}];
  set long_ident_now 0;
  if {$long_ident_interval != 0} {
    set long_ident_now \
      	    [expr {($hour * 60 + $minute) % $long_ident_interval == 0}];
  }

  if {$long_ident_now} {
    puts "$logic_name: Sending long identification...";
    send_long_ident $hour $minute;
    set prev_ident $now;
    set need_ident 0;
  } else {
    if {$now - $prev_ident < $min_time_between_ident} {
      return;
    }
    if {$ident_only_after_tx && !$need_ident} {
      return;
    }

    if {$short_ident_now} {
      puts "$logic_name: Sending short identification...";
      send_short_ident $hour $minute;
      set prev_ident $now;
      set need_ident 0;
    }
  }
}


#
# Executed when the QSO recorder is being activated
#
proc activating_qso_recorder {} {
  playMsg "Core" "activating";
  playMsg "Core" "qso_recorder";
}


#
# Executed when the QSO recorder is being deactivated
#
proc deactivating_qso_recorder {} {
  playMsg "Core" "deactivating";
  playMsg "Core" "qso_recorder";
}


#
# Executed when trying to deactivate the QSO recorder even though it's
# not active
#
proc qso_recorder_not_active {} {
  playMsg "Core" "qso_recorder";
  playMsg "Core" "not_active";
}


#
# Executed when trying to activate the QSO recorder even though it's
# already active
#
proc qso_recorder_already_active {} {
  playMsg "Core" "qso_recorder";
  playMsg "Core" "already_active";
}


#
# Executed when the timeout kicks in to activate the QSO recorder
#
proc qso_recorder_timeout_activate {} {
  playMsg "Core" "timeout"
  playMsg "Core" "activating";
  playMsg "Core" "qso_recorder";
}


#
# Executed when the timeout kicks in to deactivate the QSO recorder
#
proc qso_recorder_timeout_deactivate {} {
  playMsg "Core" "timeout"
  playMsg "Core" "deactivating";
  playMsg "Core" "qso_recorder";
}


#
# Executed when the user is requesting a language change
#
proc set_language {lang_code} {
  global logic_name;
  puts "$logic_name: Setting language $lang_code (NOT IMPLEMENTED)";

}


#
# Executed when the user requests a list of available languages
#
proc list_languages {} {
  global logic_name;
  puts "$logic_name: Available languages: (NOT IMPLEMENTED)";

}


#
# Executed when the node is being brought online or offline
#
proc logic_online {online} {
  global mycall
  variable CFG_TYPE

  if {$online} {
    playMsg "Core" "online";
    spellWord $mycall;
    if {$CFG_TYPE == "Repeater"} {
      playMsg "Core" "repeater";
    }
  }
}


##############################################################################
#
# Main program
#
##############################################################################

if [info exists CFG_SHORT_IDENT_INTERVAL] {
  if {$CFG_SHORT_IDENT_INTERVAL > 0} {
    set short_ident_interval $CFG_SHORT_IDENT_INTERVAL;
  }
}

if [info exists CFG_LONG_IDENT_INTERVAL] {
  if {$CFG_LONG_IDENT_INTERVAL > 0} {
    set long_ident_interval $CFG_LONG_IDENT_INTERVAL;
    if {$short_ident_interval == 0} {
      set short_ident_interval $long_ident_interval;
    }
  }
}

if [info exists CFG_IDENT_ONLY_AFTER_TX] {
  if {$CFG_IDENT_ONLY_AFTER_TX > 0} {
    set ident_only_after_tx $CFG_IDENT_ONLY_AFTER_TX;
  }
}

if [info exists CFG_SHORT_ANNOUNCE_ENABLE] {
  set short_announce_enable $CFG_SHORT_ANNOUNCE_ENABLE
}

if [info exists CFG_SHORT_ANNOUNCE_FILE] {
  set short_announce_file $CFG_SHORT_ANNOUNCE_FILE
}

if [info exists CFG_SHORT_VOICE_ID_ENABLE] {
  set short_voice_id_enable $CFG_SHORT_VOICE_ID_ENABLE
}

if [info exists CFG_SHORT_CW_ID_ENABLE] {
  set short_cw_id_enable $CFG_SHORT_CW_ID_ENABLE
}

if [info exists CFG_LONG_ANNOUNCE_ENABLE] {
  set long_announce_enable $CFG_LONG_ANNOUNCE_ENABLE
}

if [info exists CFG_LONG_ANNOUNCE_FILE] {
  set long_announce_file $CFG_LONG_ANNOUNCE_FILE
}

if [info exists CFG_LONG_VOICE_ID_ENABLE] {
  set long_voice_id_enable $CFG_LONG_VOICE_ID_ENABLE
}

if [info exists CFG_LONG_CW_ID_ENABLE] {
  set long_cw_id_enable $CFG_LONG_CW_ID_ENABLE
}


# end of namespace
}

#
# This file has not been truncated
#
