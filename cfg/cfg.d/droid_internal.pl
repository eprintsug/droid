#######################################################
###                                                 ###
###   Preserv2/EPrints DROID Configuration          ###
###                                                 ###
#######################################################
###                                                 ###
###     Developed by David Tarrant and Tim Brody    ###
###                                                 ###
###          Released under the GPL Licence         ###
###           (c) University of Southampton         ###
###                                                 ###
###        Install in the following location:       ###
###      eprints/archives/archive_name/cfg/cfg.d/   ###
###                                                 ###
#######################################################

# The location of the DROID JAR file
$c->{"executables"}->{"droid"} = $c->{lib_path}.'/bin/DROID/droid.jar';

# The location of the DROID signature file
$c->{"droid_sig_file"} = $c->{lib_path}.'/bin/DROID/DROID_SignatureFile.xml';

# DROID's invocation syntax
# DROID 3
#$c->{"invocation"}->{"droid"} = '$(java) -jar $(droid) -S$(SIGFILE) -FXML -A$(SOURCE) -O$(TARGET) >/dev/null';
# DROID 4
$c->{"invocation"}->{"droid"} = '$(java) -jar $(droid) -s$(SIGFILE) -fXML -a$(SOURCE) -o$(TARGET) >/dev/null';
$c->{"invocation"}->{"droid_update"} = '$(java) -jar $(droid) -d $(SIGFILE)';
$c->{"invocation"}->{"droid_rehash"} = '$(java) -jar $(droid) -s $(SIGFILE)';
