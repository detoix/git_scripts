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

