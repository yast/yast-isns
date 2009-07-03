# Makefile.am for isns/src

yncludedir = @yncludedir@/isns

client_DATA =			\
	isns.ycp		\
	isns_auto.ycp	\
	isns_proposal.ycp	\
	isns_finish.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	widgets.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	isns.desktop

module_DATA =			\
	IsnsServer.ycp

# create a symlink for local build, #145327
isns:
	ln -sf . $@
ycpchook = isns

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
