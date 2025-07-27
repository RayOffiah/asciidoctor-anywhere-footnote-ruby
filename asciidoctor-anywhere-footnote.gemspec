# asciidoctor-anywhere-footnote.gemspec
Gem::Specification.new do |spec|
  spec.name          = "asciidoctor-anywhere-footnote"
  spec.version       = "1.0.3"
  spec.authors       = ["Ray Offiah"]
  spec.email         = ["ray.offiah@couchbase.com"]

  spec.summary       = "An Asciidoctor extension for placing footnotes anywhere in the document"
  spec.description   = "This extension allows you to place footnotes near their referenced content rather than at the end of the document, with support for multiple footnote blocks, custom formatting, and reference management."
  spec.homepage      = "https://github.com/RayOffiah/asciidoctor-anywhere-footnote-ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.5.0"

  # Specify which files should be added to the gem when it is released
  spec.files         = Dir[
    "lib/**/*",
    "README.md",
    "LICENSE",
    "*.gemspec"
  ]

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_runtime_dependency "asciidoctor", "~> 2.0"
  spec.add_runtime_dependency "ruby-enum", "~> 1.0"
  spec.add_runtime_dependency "roman-numerals", "~> 0.3"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end