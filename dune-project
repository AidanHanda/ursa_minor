(lang dune 3.4)

(name ursa_minor)

(generate_opam_files true)

(source
 (github aidanhanda/ursa_minor))

(authors "aidanhanda")

(maintainers "aidanhanda")

(license LICENSE)

(package
 (name ursa_minor)
 (synopsis "DNS Updated based on current IP")
 (description "Connects with cloud providers to keep dns records in sync with the current state of the world")
 (depends ocaml dune core async core_unix core_unix.command_unix async_ssl cohttp-async)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
