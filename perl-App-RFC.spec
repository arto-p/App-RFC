Name:           perl-App-RFC
Version:        %{_VERSION}
Release:        1%{?dist}
Summary:        Module and script for reading rfc documents
Group:          System Tools/Perl
License:        GPL-1.0-or-later OR Artistic-1.0-Perl
Url:            https://arto.homeunix.org/%{name}
Source:         App-RFC-%{version}.tar.gz
BuildRequires:  make
Requires:       perl, perl(File::Find), perl(IO), perl(Text::Glob)
Requires:       perl(Time::Local), perl(Text::Wrapper), perl(HTTP::Date)
Requires:       perl(Pod::Usage), perl(Set::Scalar), perl(Getopt::Long)

BuildArch:      noarch

%global debug_package %{nil}

%description
This package provides a Perl module and script for reading RFC documents.
The module can be used to parse and extract information from RFC files,
while the script allows users to easily access and read RFCs from the command
line.

%prep
%setup -q -n App-RFC-%{version}
%build
%{__perl} Makefile.PL INSTALLDIRS=vendor NO_PACKLIST=1
%{__make} %{?_smp_mflags}

%install
%{__make} pure_install DESTDIR=%{buildroot}
%{__install} -D -Z -m644 rfc.conf %{buildroot}%{_sysconfdir}/rfc.conf
find %{buildroot} -type f -name '*.bs' -size 0 -delete
%{_fixperms} %{buildroot}


%files
%doc README
%config %{_sysconfdir}/rfc.conf
%{_bindir}/*
%{_mandir}/man1/*
%{_mandir}/man3/*
%{_datadir}/perl5/vendor_perl/*

%changelog
* Sun Nov  1 2026 Artur Penttinen  - 0.06 1
