class NextoneAgent < Formula
  desc "Bootstrap CLI for installing and configuring NextOne Agent"
  homepage "https://github.com/s3d1K0/homebrew-nextone"
  url "https://github.com/s3d1K0/NextOne-Agent.git", branch: "main", using: GitDownloadStrategy
  version "0.1.2"

  depends_on "python@3.12"

  def install
    libexec.install "nextone-cli/src/nextone_cli"

    (bin/"nextone").write <<~SH
      #!/bin/bash
      export PYTHONPATH="#{libexec}:${PYTHONPATH}"
      PYTHON_BIN="#{Formula["python@3.12"].opt_bin}/python3.12"
      if [[ ! -x "${PYTHON_BIN}" ]]; then
        PYTHON_BIN="#{Formula["python@3.12"].opt_bin}/python3"
      fi
      exec "${PYTHON_BIN}" -m nextone_cli.cli "$@"
    SH
  end

  test do
    output = shell_output("#{bin}/nextone --help")
    assert_match "nextone setup", output
  end
end
