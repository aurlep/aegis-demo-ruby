# INTENTIONALLY INSECURE — a target for Brakeman / Semgrep.
# Not required by app.rb; it exists so the generated pipeline has real findings.
# Do not copy any of this into real code.

require "digest"

# Hardcoded secrets — secret scanners (Gitleaks, TruffleHog) should flag these.
# Deliberately generic (not a real provider format) so GitHub push protection
# does not block the commit, while pattern/entropy scanners still catch them.
API_KEY = "a3f8b1c9d7e2f4a6b8c0d2e4f6a8b0c2e1d3f5a7".freeze
DB_PASSWORD = "SuperSecret123!".freeze

module InsecureDemo
  module_function

  # Command injection: untrusted input into a shell.
  def run_command(user_input)
    system("ping -c 1 #{user_input}")
  end

  # Arbitrary code execution via eval.
  def evaluate(expr)
    eval(expr) # rubocop:disable Security/Eval
  end

  # Unsafe deserialization.
  def deserialize(blob)
    Marshal.load(blob) # rubocop:disable Security/MarshalLoad
  end

  # Broken hashing: MD5 for a password digest.
  def weak_hash(password)
    Digest::MD5.hexdigest(password)
  end
end
