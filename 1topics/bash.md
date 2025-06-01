# Bash

[Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/)

* [Chapter 7. Conditional statements](https://tldp.org/LDP/Bash-Beginners-Guide/html/chap_07.html)

Bash Tips:

* [Bash Tips #1 – Logging in Shell Scripts](https://blog.tratif.com/2023/01/09/bash-tips-1-logging-in-shell-scripts/)
* [Bash Tips #2 – Splitting Shell Scripts to Improve Readability](https://blog.tratif.com/2023/01/27/bash-tips-2-splitting-shell-scripts-to-improve-readability/)
* [Bash Tips #3 – Templating in Bash Scripts](https://blog.tratif.com/2023/01/27/bash-tips-3-templating-in-bash-scripts/)
* [Bash Tips #4 – Error Handling in Bash Scripts](https://blog.tratif.com/2023/01/30/bash-tips-4-error-handling-in-bash-scripts/)
* [Logging and monitoring from Bash scripts](https://www.linuxbash.sh/post/logging-and-monitoring-from-bash-scripts)

Bash string substitution is a powerful tool for manipulating strings. It allows for extracting substrings, replacing parts of strings, and changing the case of strings. Here's an overview of common string substitution techniques in Bash:

Substring Extraction:

* ${string:position}: Extracts the substring starting at position.
* ${string:position:length}: Extracts a substring of length characters starting at position.
  
Substring Replacement:

* ${string/pattern/replacement}: Replaces the first occurrence of pattern with replacement.
* ${string//pattern/replacement}: Replaces all occurrences of pattern with replacement.
* ${string/#pattern/replacement}: Replaces pattern with replacement only if pattern matches the beginning of the string.
* ${string/%pattern/replacement}: Replaces pattern with replacement only if pattern matches the end of the string.
  
Case Modification:

* ${string^^}: Converts the string to uppercase.
* ${string,,}: Converts the string to lowercase.
* ${string^}: Converts the first character of the string to uppercase.
* ${string,}: Converts the first character of the string to lowercase.
  
String Length:

* ${#string}: Returns the length of the string.

Default Values:

* ${variable:-default}: If variable is unset or null, it expands to default.
* ${variable:=default}: If variable is unset or null, it's assigned the value default and then expands to that value.
* ${variable:?error_message}: If variable is unset or null, it prints error_message and exits.
* ${variable:+alternative}: If variable is set, it expands to alternative; otherwise, it expands to nothing.

These techniques can be combined and nested to achieve complex string manipulations. For example, to extract the filename from a path and convert it to lowercase, one could use ${filename##*/,,}.

## Other

[Murex](https://github.com/lmorg/murex)

## Unit Tests

* [Install](https://github.com/ztombol/bats-docs)
  * [bats-support](https://github.com/ztombol/bats-support)
* [Bats-core: Bash Automated Testing System](https://github.com/bats-core/bats-core)
* [Welcome to bats-core’s documentation!](https://bats-core.readthedocs.io/en/stable/)

## Bash frameworks

[Bashmatic® — BASH-based DSL helpers for humans, sysadmins, and fun.](https://github.com/kigster/bashmatic)

[oh-my-bash](https://github.com/ohmybash/oh-my-bash)

[bash-it](https://github.com/Bash-it/bash-it)

[bash-oo-framework](https://github.com/niieani/bash-oo-framework)

[shellcheck, script validation](https://github.com/koalaman/shellcheck)

[bashly.dev, script generation](https://bashly.dev/examples/)

## Small functions

* [Message with border](https://www.youtube.com/watch?v=GuPmqAXy6TI)
* [Message with border](https://gitlab.com/edmitry2010/obsidian-open-git/-/tree/main/bash/%D0%9E%D1%84%D0%BE%D1%80%D0%BC%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5)