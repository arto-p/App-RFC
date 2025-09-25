Name:           rfc-new-index
Version:        %{_VERSION}
Release:        1%{?dist}
Summary:        Application for search rfc by number
Group:          System Tools/Files
License:        MIT
Url:            https://arto.homeunix.org/%{name}
Source:         %{name}-%{version}.tar.gz
Requires:       perl
BuildRequires:  systemd-rpm-macros
BuildArch:      noarch

%global debug_package %{nil}

%{?systemd_requires}

%description
Tools for discovering, sorting and removing of duplicate files.

%prep
%setup -q
%build
%install
%{__install} -D -Z -m755 %{name}.zsh       $RPM_BUILD_ROOT%{_systemd_util_dir}/systemd-%{name}
%{__install} -D -Z -m644 %{name}.service   $RPM_BUILD_ROOT%{_unitdir}/%{name}.service
%{__install} -D -Z -m644 %{name}.timer     $RPM_BUILD_ROOT%{_unitdir}/%{name}.timer
%{__install} -D -Z -m644 %{name}.tmpfiles  $RPM_BUILD_ROOT%{_tmpfilesdir}/%{name}.conf
%{__install} -D -Z -m644 %{name}.preset    $RPM_BUILD_ROOT%{_presetdir}/95-%{name}.preset

%post
if [ $1 -ge 1 ]; then
	systemd-tmpfiles --create %{_tmpfilesdir}/%{name}.conf
	%systemd_post %{name}.timer
fi

%files
%doc README.md
%license LICENSE
%{_systemd_util_dir}/systemd-%{name}
%{_unitdir}/%{name}.service
%{_unitdir}/%{name}.timer
%{_tmpfilesdir}/*
%{_presetdir}/*

%changelog
* Sat Mar 29 2025 Artur Penttinen 0.1 1
- First release

* Tue Apr  1 2025 Artur Penttinen 0.8 1
- Many improvements.
- Added ability to download new RFCs.
