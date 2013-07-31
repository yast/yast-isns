# Sources for isns

module_DATA = \
  modules/IsnsServer.rb

client_DATA = \
  clients/isns.rb \
  clients/isns_proposal.rb \
  clients/isns_auto.rb \
  clients/isns_finish.rb

yncludedir = @yncludedir@/isns
ynclude_DATA = \
  include/isns/widgets.rb \
  include/isns/wizards.rb \
  include/isns/dialogs.rb \
  include/isns/complex.rb \
  include/isns/helps.rb

scrconf_DATA = \
  scrconf/isnsd.scr

desktop_DATA = \
  desktop/isns.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common