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
  desktop/org.opensuse.yast.iSNS.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-isns-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-isns.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
