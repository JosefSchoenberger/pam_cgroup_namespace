pam_cgroup_namespace.so: pam_cgroup_namespace.o

LINK_LIBRARIES:=pam

OUTPUTS:=pam_cgroup_namespace.so


# ------------------------ DEFAULTS ------------------------

WFLAGS?=-Wall -Wextra
DBGFLAGS?=
OPTFLAGS?=
DEFFLAGS?=
EXTRAFLAGS?=

BUILDDIR?=build

# ----------------------- MAKE RULES -----------------------

CSOURCES=$(shell find -maxdepth 1 -name '*.c')
CPPSOURCES=$(shell find -maxdepth 1 -name '*.cpp')

ifneq "$(VERBOSE)" "y"
	Q=@
else
	Q=
endif

ifneq "$(CC)" "default"
	CC=gcc
endif
ifneq "$(CXX)" "default"
	CXX=g++
endif
ifneq "$(LD)" "default"
	LD=$(CXX)
endif

VPATH:=$(BUILDDIR) # also search for files in BUILDDIR for dependencies (e.g. object files)
MAKEFLAGS+=-Rr # ignore standard make recipes
CCFLAGS=$(WFLAGS) $(OPTFLAGS) $(DEBUGFLAGS) $(EXTRAFLAGS) $(DEFFLAGS) -fPIC
LDFLAGS=$(DEBUGFLAGS) $(addprefix -l, $(LINK_LIBRARIES)) -shared -Wl,-z,relro

.PHONY: debug release clean deepclean
debug: $(.DEFAULT_GOAL)
debug: DEBUGFLAGS+=-g
debug: DEFFLAGS+=-DDEBUG

release: $(.DEFAULT_GOAL)
release: OPTFLAGS+=-O2

clean:
	$(Q)rm -f $(OUTPUTS)
	$(Q)rm -f $(shell test -d $(BUILDDIR) && find $(BUILDDIR) -type f -not -name '*.d')

deepclean:
	$(Q)rm -f $(OUTPUTS)
	$(Q)rm -rf $(BUILDDIR)
	$(Q)rm -rf $(TO_DEEP_CLEAN)


$(OUTPUTS): %:
	@printf "[ %3s ] linking   %-22s from [ %s ]\n" $(LD) $@ "$(notdir $^)"
	$(Q)$(LD) $^ -o $@ $(LDFLAGS)

$(addprefix $(BUILDDIR)/,$(notdir $(CSOURCES:.c=.o))): $(BUILDDIR)/%.o: %.c | $(BUILDDIR)
	@printf "[ %3s ] compiling %-22s from %s\n" $(CC) "$(notdir $@)" "$(notdir $<)"
	$(Q)$(CC) -r $(WFLAGS) $(CCFLAGS) $< $(sort $(filter %.o,$^)) -o $@ -MMD -MT $@ -MF $(BUILDDIR)/$(notdir $(@:.o=.d))

$(addprefix $(BUILDDIR)/,$(notdir $(CPPSOURCES:.cpp=.o))): $(BUILDDIR)/%.o: %.cpp | $(BUILDDIR)
	@printf "[ %3s ] compiling %-22s from %s\n" $(CXX) "$(notdir $@)" "$(notdir $<)"
	$(Q)$(CXX) -std=c++20 -c $(CCFLAGS) $< $(sort $(filter %.o,$^)) -o $@ -MMD -MT $@ -MF $(BUILDDIR)/$(notdir $(@:.o=.d))

$(BUILDDIR):
	$(Q)mkdir -p $@

.PHONY: install
install: release
	$(Q)install -Dvp -m 0644 -o root -g root -t /lib/x86_64-linux-gnu/security/ pam_cgroup_namespace.so


include $(wildcard $(BUILDDIR)/*.d)
