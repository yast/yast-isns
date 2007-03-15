# Makefile.am for isns/src

yncludedir = @yncludedir@/isns

client_DATA =			\
	isns.ycp		\
	isns_finish.ycp		\
	inst_isns.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	widgets.ycp

desktop_DATA =			\
	isns.desktop

module_DATA =			\
	IsnsServer.ycp		

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
