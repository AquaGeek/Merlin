## Introduction

The goal of Merlin is to create a very lightweight Objective-C database abstraction layer for iOS and Mac OS X. It is inspired by and modeled after Rails' {ActiveRecord}[https://github.com/rails/rails/active_record].

The project follows Vincent Driessen's {Git branching model}[http://nvie.com/posts/a-successful-git-branching-model/]. Because it is still in the early phases, you will probably want to explore the {develop}[https://github.com/AKQADC/Merlin/tree/develop] branch for the latest and greatest "edge" features.

## Project layout

The code for the static library is found in the Library folder. Documentation and an example Xcode project will eventually be added to the root level as well.

## How it works

{MLBase}[https://github.com/AKQADC/Merlin/blob/develop/Library/Merlin/MLBase.m] is an abstract superclass for database models. When rows are fetched from the database, each column is read into the 'attributes' dictionary. Additionally, MLBase includes some introspection code to automatically add getter and setter methods for each column in your table's schema to your subclass. This allows you to do things like:

    person = [Person first];
    [person setLastName:@"Anderson"];

To silence the compiler warnings, you can add dynamic properties to your class - similar to how things work with Core Data:

    // Person.h
    
    #import <Foundation/Foundation.h>
    
    #import "MLBase.h"
    
    @interface Person : MLBase
    
    @property (nonatomic, retain) NSString *lastName;
    
    @end

    // Person.m
    
    #import "Person.h"
    
    @implementation Person
    
    @dynamic lastName;
    
    @end

## Getting Started

1. Add Merlin to your project as a Git submodule:

    `git submodule add git://github.com/AKQADC/Merlin.git`

1. Add your SQLite database file to your project.
1. Create your 
1. More to come...

## Versioning your SQLite database

In lieu of just adding a pre-built database file to your project, you can also have Xcode generate the database for you from SQL. This allows you to keep track of db schema changes via SCM.

1. Add a file to your project with a '.sql' extension that contains the necessary SQL to generate your models' tables:

    CREATE TABLE people(id INTEGER PRIMARY KEY AUTOINCREMENT, firstName TEXT NOT NULL, lastName TEXT NOT NULL, email TEXT);

1. Open your project's build rules. Click "Add Build Rule." Select "Source files with names matching:" from the "Process" drop-down and enter *.sql in the text field. Select "Custom script:" from the "Using" drop-down and enter:

    # Adapted from http://tom.wilcoxen.org/2008/11/28/build-and-compile-your-sqlite-database-with-xcode/
    # Remove the old built db
    cd "${TARGET_BUILD_DIR}"
    if [ -f ${INPUT_FILE_BASE}.db ];
    then
    rm ${INPUT_FILE_BASE}.db;
    fi
    
    # Build the new one
    cat "${INPUT_FILE_PATH}" | sqlite3 ${INPUT_FILE_BASE}.db

Now, whenever you build your project, a fresh database will be generated and added to your app's resources.

## Contributing

We encourage forks, patches, feedback, bug reports, etc.

## License

Merlin is released under the BSD license.
