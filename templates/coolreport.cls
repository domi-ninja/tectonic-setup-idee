\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{coolreport}[2026/07/15 Simple customer report template]

\LoadClass[11pt,a4paper]{article}

\RequirePackage{fontspec}
\RequirePackage[ngerman]{babel}
\RequirePackage[a4paper,margin=24mm,headheight=15pt]{geometry}
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\RequirePackage{pdfpages}
\RequirePackage{booktabs}
\RequirePackage{tabularx}
\RequirePackage{enumitem}
\RequirePackage{fancyhdr}
\RequirePackage{lastpage}
\RequirePackage{titlesec}
\RequirePackage{hyperref}

% Dateibasierte Font-Auswahl: funktioniert ohne systemweites Fontconfig und
% bleibt auf Windows, macOS und Linux reproduzierbar.
\setsansfont{texgyreheros}[
  Extension=.otf,
  UprightFont=*-regular,
  BoldFont=*-bold,
  ItalicFont=*-italic,
  BoldItalicFont=*-bolditalic
]
\renewcommand{\familydefault}{\sfdefault}

\definecolor{ReportNavy}{HTML}{16324F}
\definecolor{ReportBlue}{HTML}{2D7DD2}
\definecolor{ReportLight}{HTML}{EEF4F8}
\definecolor{ReportText}{HTML}{25313C}

\hypersetup{
  colorlinks=true,
  linkcolor=ReportBlue,
  urlcolor=ReportBlue
}

\setlength{\parindent}{0pt}
\setlength{\parskip}{0.7em}
\setlist{nosep,leftmargin=1.5em}
\titleformat{\section}{\Large\bfseries\color{ReportNavy}}{\thesection}{0.65em}{}
\titleformat{\subsection}{\large\bfseries\color{ReportNavy}}{\thesubsection}{0.65em}{}

\newcommand{\reporttitle}{Report}
\newcommand{\reportsubtitle}{}
\newcommand{\reportcustomer}{Kunde}
\newcommand{\reportdate}{\today}
\newcommand{\reportauthor}{Cool Doc Flow}
\newcommand{\reportclassification}{Vertraulich}

\pagestyle{fancy}
\fancyhf{}
\lhead{\textcolor{ReportNavy}{\reportcustomer}}
\rhead{\textcolor{ReportNavy}{\reporttitle}}
\lfoot{\footnotesize\reportclassification}
\rfoot{\footnotesize Seite \thepage\ von \pageref*{LastPage}}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\newcommand{\reporttitlepage}{%
  \hypersetup{pageanchor=false}
  \begin{titlepage}
    \vspace*{20mm}
    {\color{ReportBlue}\rule{26mm}{3pt}}\\[14mm]
    {\Huge\bfseries\color{ReportNavy}\reporttitle\par}
    \vspace{4mm}
    {\Large\color{ReportText}\reportsubtitle\par}
    \vfill
    \begin{tabularx}{\textwidth}{@{}>{\bfseries}l X@{}}
      Kunde & \reportcustomer \\
      Datum & \reportdate \\
      Autor & \reportauthor \\
      Klassifikation & \reportclassification
    \end{tabularx}
    \vspace{12mm}
  \end{titlepage}
  \setcounter{page}{1}
  \hypersetup{pageanchor=true}
}

\newcommand{\reportfigure}[2]{%
  \begin{figure}[htbp]
    \centering
    \includegraphics[width=\linewidth,height=0.68\textheight,keepaspectratio]{#1}
    \caption{#2}
  \end{figure}
}

\newcommand{\reportattachment}[1]{%
  \clearpage
  \includepdf[pages=-,pagecommand={}]{#1}
}

\newenvironment{reportsummary}{%
  \par\medskip
  \noindent\begin{minipage}{\textwidth}
  \raggedright
  \color{ReportText}
  \textcolor{ReportBlue}{\rule{\textwidth}{2pt}}\par\smallskip
  \textbf{Zusammenfassung}\par
}{%
  \smallskip\textcolor{ReportBlue}{\rule{\textwidth}{0.5pt}}
  \end{minipage}
  \par\medskip
}
