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

# oneliners

Visit [git mining](https://objectequals.com/git-mining/) plus see some oneliners below:

Prints all files prefixed with number of lines, ordered

```
git ls-files | xargs -I{} wc -l {} | sort -g -r
```
