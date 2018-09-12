FROM buildpack-deps:bionic-scm

# QuID
ENV DEBIAN_FRONTEND noninteractive
RUN set -ex ; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		apt-transport-https \
		build-essential \
	; \
	rm -rf /var/lib/apt/lists/* ;

# Python 3.6.4
# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# extra dependencies (over what buildpack-deps already includes)
RUN set -ex ; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		tcl-dev \
		tk-dev \
		libssl-dev \
		libsqlite3-dev \
	; \
	rm -rf /var/lib/apt/lists/* ;

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.6.4

RUN set -ex ;\
	wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" ; \
	wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" ; \
	export GNUPGHOME="$(mktemp -d)" ; \
	gpg --keyserver keyserver.ubuntu.com --recv-keys "$GPG_KEY" ; \
	gpg --batch --verify python.tar.xz.asc python.tar.xz ; \
	{ command -v gpgconf > /dev/null && gpgconf --kill all || :; } ; \
	rm -rf "$GNUPGHOME" python.tar.xz.asc ; \
	mkdir -p /usr/src/python ; \
	tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz ; \
	rm python.tar.xz ; \
	\
	cd /usr/src/python ; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" ; \
	./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	; \
	make -j "$(nproc)" ; \
	make install ; \
	ldconfig ; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + ; \
	rm -rf /usr/src/python ; \
	\
	python3 --version ;

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.0

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

RUN set -ex ; \
	pip install --no-cache-dir \
		"numpy<1.15,>=1.13" \
	;

# Q#
WORKDIR /root/qsharp
RUN set -ex ; \
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - ; \
	wget -qO /etc/apt/sources.list.d/microsoft-prod.list https://packages.microsoft.com/config/ubuntu/18.04/prod.list ; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		dotnet-sdk-2.1 \
	; \
	rm -rf /var/lib/apt/lists/* ; \
	dotnet new -i "Microsoft.Quantum.ProjectTemplates::0.2.1806.3001-preview" ;

ADD ["qsharp/Quantum", "quantum"]

WORKDIR /root/qsharp/quantum/Samples/H2SimulationGUI
RUN set -ex ; \
	wget -qO- https://deb.nodesource.com/setup_8.x | bash - ; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		nodejs \
		libgtk-3-0 \
		libxtst6 \
		libgconf-2-4 \
		libnss3 \
		libasound2 \
		xvfb \
	; \
	rm -rf /var/lib/apt/lists/* ; \
	npm install ;

# Doesn't fully work due to pythonnet
# Anyway, only supported on Windows
WORKDIR /root/qsharp/quantum/Samples/PythonInterop
RUN set -ex ; \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF ; \
	echo "deb https://download.mono-project.com/repo/debian stable/snapshots/4.8 main" > /etc/apt/sources.list.d/mono-official-stable.list ; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		nuget \
		clang \
	; \
	pip install --no-cache-dir \
		cython \
		numpy \
		scipy \
		pycparser \
	; \
	pip install --no-cache-dir \
		jupyter \
		future \
		# pythonnet \
		qutip \
		matplotlib \
		ipyparallel \
		py \
		/root/qsharp/quantum/Interoperability/python \
		qinfer \
		duecredit \
		mpltools \
	; \
	dotnet build ;

WORKDIR /root/qsharp
RUN ln -s quantum/Samples examples

ADD ["qsharp/QuantumKatas", "tutorial"]

# ProjectQ
WORKDIR /root/projectq
RUN set -ex ; \
	pip install --no-cache-dir \
		projectq==0.4.1 \
	;

ADD ["projectq/ProjectQ/README.rst", "README.rst"]
ADD ["projectq/ProjectQ/docs",       "docs"]
ADD ["projectq/ProjectQ/examples",   "examples"]

# Cirq
WORKDIR /root/cirq
RUN set -ex ; \
	pip install --no-cache-dir \
		cirq==0.3.1.35 \
	; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		texlive-latex-base \
		latexmk \
	; \
	rm -rf /var/lib/apt/lists/* ;

ADD ["cirq/Cirq/README.rst", "README.rst"]
ADD ["cirq/Cirq/docs",       "docs"]
ADD ["cirq/Cirq/examples",   "examples"]

# Qiskit
WORKDIR /root/qiskit
RUN set -ex ; \
	pip install --no-cache-dir \
		qiskit==0.5.7 \
		qiskit-aqua==0.2.0 \
		jupyter \
	; \
	apt-get update ; \
	apt-get install -y --no-install-recommends \
		texlive-latex-base \
		texlive-latex-extra \
		texlive-pictures \
		poppler-utils \
	; \
	rm -rf /var/lib/apt/lists/* ;

EXPOSE 8888

ADD ["https://raw.githubusercontent.com/Qiskit/qiskit-terra/0.5.7/Qconfig.py.default", "Qconfig.py"]
ADD ["qiskit/qiskit-tutorial", "tutorial"]
ADD ["qiskit/qiskit_tutorial", "tutorial2"]
ADD ["qiskit/aqua-tutorials",  "tutorial-aqua"]

# Rigetti Forest / PyQuil
WORKDIR /root/pyquil
RUN set -ex ; \
	pip install --no-cache-dir \
		pyquil==1.9.0 \
		quantum-grove==1.7.0 \
	;

ADD ["pyquil/.pyquil_config",      "pyquil_config"]
ENV PYQUIL_CONFIG /root/pyquil/pyquil_config
ADD ["pyquil/pyquil/README.md",    "README.md"]
ADD ["pyquil/pyquil/examples",     "examples"]
ADD ["pyquil/pyquil-quantum-dice", "tutorial"]

# QuID
WORKDIR /root
ADD ["cheatsheet/cheatsheet.pdf", "cheatsheet.pdf"]

ENV DISPLAY :9.0
CMD \
	(Xvfb -ac -screen scrn 1280x2000x24 $DISPLAY >/dev/null 2>&1 &) && \
	(jupyter notebook --ip='*' --NotebookApp.token='' --no-browser --allow-root >/dev/null 2>&1 &) && \
	echo "Open 127.0.0.1:8888 to access Jupyter Notebook" && \
	bash
