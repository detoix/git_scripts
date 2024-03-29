These scripts serve the purpose of retrieving valuable information from git repositories.

# snapshot.sh

Prints state of git repository at the current commit.
Let's assume your repository consists of only single file exact to the following.

```
using System;

namespace Foo
{
    public class Bar
    {
        public int MyProperty { get; set; }
        private int _myField;

        public Bar()
        {

        }
    }
}
```

```
bash snapshot.sh -r | tee file.csv
```

Running this command will print the following output in a comma-separated format.
When put into an Excel spreadsheet it will look like this:

| File          | Lines_count   | Commit_count_within_time_span | Leading_spaces |
| ------------- | ------------- | ----------------------------- | -------------- |
| src/file.cs   | 17            | 1                             | 52             |

- **File** represents path to file under git version control
- **Lines_count** simply calculates all lines within file
- **Commit_count_within_time_span** prints count of commits within a year since now
- **Leading_spaces** counts all whitespaces appearing before any other character in code (this should more or less represent complexity - the more indentation the more complex the code)

Similar result can be achieved with this oneliner:

```
git ls-files | xargs -I{} sh -c 'printf "{}\t" ; cat "{}" | printf "`wc -l`\t" ; git log --after="1 year ago" --oneline "{}" | printf "`wc -l`\t" ; grep -o '^[[:blank:]]*' "{}" | tr -d "\n" | wc -c'
```

# oneliners

Visit [git mining](https://objectequals.com/git-mining/) plus see some oneliners below:

Prints all files prefixed with number of lines, ordered

```
git ls-files -z | xargs -0 wc -l | sort -g -r
```

Prints all meaningful lines, i.e., lines that have at least one number or letter

```
git ls-files -z | xargs -0 grep '[[:alnum:]]' | wc -l
```

Print tsv, where first column is file path and second column is meaningful lines count in this file

```
git ls-files -z | xargs -0 -n 1 sh -c 'printf "$0\t" ; grep "[[:alnum:]]" "$0" | wc -l'
```

Fast count leading spaces

```
git ls-files -z | xargs -0 grep -ho '^[[:blank:]]*' | tr -d '\n' | wc -c
```

Count all tokens

```
git ls-files -z | xargs -0 grep -h '[[:alnum:]]' | tr -s '[:space:]' '\n' | wc -l
```
