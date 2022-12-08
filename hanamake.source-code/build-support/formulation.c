char * left_justified
( char const * cstring
)
{ while(*cstring == ' ') cstring++;
  return (char *)cstring;
}


//#############################################################################

/* Determine topological ordering,
   (a pseudo-topological ordering if circular dependencies are present)

   So that code objects are placed after their dependencies in top[] */


/* First, create implicitly available variables */

typedef size_t     code_object_index;
typedef size_t     code_object_dependency_index;

code_object_index  top[code_objects];
code_object_index  top_iterator = 0;

enum { unsorted, sorted, in_recursion }
top_status[code_objects] = { unsorted };


/* Declare the recursive step of topological sorting */

void topological_sort_visit
( code_object_index const C
) ;


/* Define the inital step / outer loop for topological sorting */

void topological_sort_dependencies
(
)
{ for
  ( code_object_index C = 0
  ; C < code_objects
  ; C++
  )
  {
    if(top_status[C] == unsorted)
       topological_sort_visit(C);
  }
}


/* Define the recursive step for topological sorting */

void topological_sort_visit
( code_object_index const C
)
{ top_status[C] = in_recursion;

  for
  ( code_object_dependency_index D = 0
  ; D < coi[C].dependencies
  ; D++
  )
  {
    if(top_status[coi[C].dependency[D]] == unsorted)
    {
      topological_sort_visit(coi[C].dependency[D]);
    }
    else
    if(top_status[coi[C].dependency[D]] == in_recursion)
    {
      /* Circular dependency detected
      -- do nothing */
    }
    else
    // Already 'sorted'
    {
      /* Forward edge detected
      -- do nothing */
    }
  }

  top[top_iterator++] = C;
  top_status[C] = sorted;
}


//#############################################################################

/* Define a recursive scanner for dependency path finding */

char function_is_dependent
( size_t const index
, size_t const subject_index
, char * const visited_object  // size is code_objects
)
{ visited_object[index] = 1;

  for(size_t D = 0; D < coi[index].dependencies; D++)
  {
    if( coi[index].dependency[D] == subject_index )
    {
      return 1;
    }
    else
    if( ! visited_object[coi[index].dependency[D]] )
    {
      if
      ( function_is_dependent
        ( coi[index].dependency[D]
        , subject_index
        , visited_object
        )
      )
      {
        return 1;
      }
    }
  }
  return 0; 
}

char __hanamade_test__is_dependent
( size_t const index
)
{ char visited_object[code_objects] = { 0 };
       visited_object[index]        =   1;

  for(size_t D = 0; D < coi[index].dependencies; D++)
  {
    if( coi[index].dependency[D] == coi[index].__hanamade_test__subject_index )
    {
      return 1;
    }
    else
    if( ! visited_object[coi[index].dependency[D]] )
    {
      if
      ( function_is_dependent
        ( coi[index].dependency[D]
        , coi[index].__hanamade_test__subject_index
        , visited_object
        )
      )
      {
        return 1;
      }
    }
  }
  return 0;
}


void finish_print_loading();


char every__hanamade_test__is_dependent
(
)
{
  char result = 1;  // look for a counter example

  for(size_t C = 0; C < code_objects; C++)
  {
    if(coi[C].__hanamade_test__)  // if C is a test
    {
      if( ! __hanamade_test__is_dependent(C))  // if C is NOT actually dependent on its subject / target
      {
        if(result == 1)
        {
          finish_print_loading();
          printf("\n-------------------------------------------------------------------------------\n");
        }
        char const * const message = "\n! UNCONNECTED :  hanamake_test  independent of target:  %s";
        printf(message, left_justified(coi[coi[C].__hanamade_test__subject_index].name));
        result = 0;
      }
    }
  }
  return result;
}


//#############################################################################

char loading = 0;
pthread_t loading_dots;
void * print_loading()
{
  fprintf(stderr, " ");
  while(loading)
  {
    usleep(50000);
    fprintf(stderr, "."); fflush(stderr);
    usleep(50000);
    fprintf(stderr, "."); fflush(stderr);
    usleep(50000);
    fprintf(stderr, "."); fflush(stderr);
    usleep(50000);
    fprintf(stderr, "\b\b\b   \b\b\b"); fflush(stderr);
  }
  printf("\b  [ Complete ]"); fflush(stdout);
  return NULL;
}

void start_print_loading()
{
  loading = 1;
  pthread_create(&loading_dots, NULL, print_loading, NULL);
}

void finish_print_loading()
{
  usleep(200000);
  loading = 0;
  void * rvalue;
  pthread_join(loading_dots, &rvalue);
}


//#############################################################################

int main(void)
{
  printf("\n- Screening for unconnected targets"); fflush(stdout);
  start_print_loading();

  if( ! every__hanamade_test__is_dependent() )
  {
    printf
    ( "\n"
      "\n  Surprisingly, the tests for the '! UNCONNECTED :' functions"
      "\n  listed above were found to be independent of their targets."
      "\n"
      "\n  This means that, unless the targets are somehow invoked via"
      "\n  function pointers, the tests for the above functions are"
      "\n  not actually testing them."
      "\n"
      "\n  Bridge the missing links between test(s) and target(s) to proceed."
      "\n"
      "\n-------------------------------------------------------------------------------"
      "\n"
    );
    return -1;
  }
  finish_print_loading();

  printf("\n- Identifying indirect dependencies"); fflush(stdout);
  start_print_loading();

  topological_sort_dependencies();
  finish_print_loading();


//#############################################################################

  printf("\n- Identifying (re)test requirements"); fflush(stdout);
  start_print_loading();

  /* Check for source file updates
     (empty logs in log/%.i(pp) produced by make)

     But first, mark no-test objects for deletion
     (to be deleted after all tests have run) */

  char marked_for_deletion[code_objects];
  for(size_t index = 0; index < code_objects; index++) { marked_for_deletion[index] = 1; }
  for(size_t index = 0; index < code_objects; index++)
  {
    if(coi[index].__hanamade_test__)
    {
      marked_for_deletion[index] = 0;
      marked_for_deletion[coi[index].__hanamade_test__subject_index] = 0;
    }
  }

  /* Now check for the source file updates */

  for(size_t index = 0; index < code_objects; index++)
  {
    /* Log file presence indicates either source update or
       prior test failure */

    if((coi[index].log_file = fopen(coi[index].log_path, "r")))
    {
      /* Getting an End Of File (EOF) value at the beginning of
         the file means its empty,
         and the corresponding source file was updated

         Getting any other value means the file is non-empty,
         indicating a prior testing failure
         (which is the default assumption, so no action is taken) */

      if(fgetc(coi[index].log_file) == EOF) coi[index].status = updated;

      /* Close and reassign NULL to log_file
         to avoid interfering with testing,
         which uses a non-NULL  log_file value to detect a failed test */

      fclose(coi[index].log_file);
      coi[index].log_file = NULL;
    }

    /* No log file means no update nor failure -- an implicit pass */

    else coi[index].status = passed;
  }


//#############################################################################

  /* Run topological dependency analysis
     setting non-updated objects that depend on objects
     with status:
     'updated' OR
     'depends' to 'depends' */

  for
  ( code_object_index index = 0
  ; index < code_objects
  ; index++
  )
  {
    if(coi[top[index]].status != updated)
    {
      for
      ( code_object_dependency_index D = 0
      ; D < coi[top[index]].dependencies
      ; D++
      )
      {
        /* Iterating through the code objects in
           TOPOLOGICAL order, get the status of each
           dependency.

           If the dependency has been
           'updated' or
           'depends' on anything,

           set the depending code object--
           NOT the dependency--
           status to 'depends'

           The result consistency check at the end handles
           the case of a passed test depending on a failed test.

           The status of the depending object can be changed with:
           coi[top[index]].status = <new_status>

           The status of the dependency can be accessed through:
           coi[coi[top[index]].dependency[D]].status */

        if(coi[coi[top[index]].dependency[D]].status == updated
        || coi[coi[top[index]].dependency[D]].status == depends
        )
        {
          coi[top[index]].status = depends;
        }
      }
    }
  }
  finish_print_loading(); printf("\n");


//#############################################################################

  /* Identify required testing based on direct updates (source file updates)
     OR
     indirect updates
     (dependency on direct update
      OR
      dependency on dependency on ... direct update
     ) */

  size_t tests_required_to_run = 0;
  size_t updates = 0;

  for(size_t index = 0; index < code_objects; index++)
  {
    switch(coi[index].status)
    {
      case updated:
        printf("\n  %s  [ updated source file ]", coi[index].name);
        updates++;

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case depends:
        printf("\n  %s  [ depends on: ", coi[index].name);

        /* Is this behavior you desire? */

        if(coi[coi[index].dependency[0]].status == updated
        || coi[coi[index].dependency[0]].status == depends
        ) printf("%s", left_justified(coi[coi[index].dependency[0]].name));

        for(size_t D = 1; D < coi[index].dependencies; D++)
          if(coi[coi[index].dependency[D]].status == updated
          || coi[coi[index].dependency[D]].status == depends
          ) printf(", %s", left_justified(coi[coi[index].dependency[D]].name));

        printf(" ]");

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case  failed:
        printf("\n  %s  [ failing ]", coi[index].name);

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case  passed: /* do nothing */
        break;
    }
  }


//#############################################################################

  /* Execute required tests and report results */
  if(tests_required_to_run || updates) printf("\n\n");
  printf("- Executing relevant function tests");
  if(tests_required_to_run > 0) printf("\n\n");
  else printf("  [ Complete ]\n");

  fflush(stdout);

  printf("  ...");

  for(size_t index = 0; index < code_objects; index++)
  {
    if(coi[index].__hanamade_test__ != NULL && coi[index].status != passed)
    {
      coi[index].__hanamade_test__
      (&(coi[index].log_file)
      ,  coi[index].log_path
      , left_justified
        (
          coi[coi[index].__hanamade_test__subject_index].name
        )
      );

      if(coi[index].log_file != NULL)
      {
        /* Part 1 */

        printf
        ( "\b\b\b%s  [ FAILED ] -- see hanamade/log\n  ..."
        , coi[coi[index].__hanamade_test__subject_index].name
        );
            coi[index].status                                 = failed;
        coi[coi[index].__hanamade_test__subject_index].status = failed;

        fclose(coi[index].log_file);

        /* Part 2 */

        coi[index].log_file =
        fopen(coi[coi[index].__hanamade_test__subject_index].log_path, "w");

        fprintf(coi[index].log_file, "See %s\n", coi[index].log_path);
        fclose(coi[index].log_file);
      }

      else
      {
        printf
        ( "\b\b\b%s  [ PASSED ]\n  ..."
        , coi[coi[index].__hanamade_test__subject_index].name
        );

            coi[index].status                                 = passed;
        coi[coi[index].__hanamade_test__subject_index].status = passed;

        marked_for_deletion[index]                                     = 1;
        marked_for_deletion[coi[index].__hanamade_test__subject_index] = 1;
      }
    }
  }


  printf("\b\b\b   \b\b\b\b\b");
  if(tests_required_to_run) { printf("\n"); }
  fflush(stdout);

  for(size_t index = 0; index < code_objects; index++)
  {
    if(marked_for_deletion[index])
    {
      remove(coi[index].log_path);
    }
  }


//#############################################################################

  printf("- Checking for inconsistent results");

  char consistent = 1;  // true

  FILE * inconsistent_test_results_log =
  fopen("inconsistent-test-results.log", "w");

  for(size_t index = 0; index < code_objects; index++)
  {
    size_t inconsistent = 0;  // reset - false

    if(coi[index].status == passed)
    {
      for(size_t D = 0; D < coi[index].dependencies; D++)
      {
        if(coi[coi[index].dependency[D]].status == failed)
        {
          /* formatting */ if(consistent) { printf("\n"); }

          inconsistent += 1;  // true
            consistent = 0;  // false

          if(inconsistent == 1)
          {
            char const * const ir_log_text_format =
            "\n  %s  [ INCONSISTENT WITH DEPENDENCY: %s";

            fprintf
            ( inconsistent_test_results_log
            , ir_log_text_format
            , coi[index].name
            , left_justified(coi[coi[index].dependency[D]].name)
            );

            printf
            ( ir_log_text_format
            , coi[index].name
            , left_justified(coi[coi[index].dependency[D]].name)
            );
          }
          else  // multiple inconsistencies
          {
            char const * const ir_log_text_format =
            ", %s";

            fprintf
            ( inconsistent_test_results_log
            , ir_log_text_format
            , coi[coi[index].dependency[D]].name
            );

            printf
            ( ir_log_text_format
            , coi[coi[index].dependency[D]].name
            );
          }
        }
      }

      if(inconsistent)
      {
        char const * const ir_log_text_format =
        " ]";

        fprintf
        ( inconsistent_test_results_log
        , ir_log_text_format
        );

        printf
        ( ir_log_text_format
        );
      }
    }
  }


  if(consistent)
  {
    /* DO NOT PRINT TO LOG. THE RESULTS ARE CONSISTENT. REMOVE THE LOG. */

    remove("inconsistent-test-results.log");
    printf("  [ Complete ]\n");
  }
  else
  {
    char const * const ir_log_text_format = "\n"
    "\n  INCONSISTENT -- Your code test results are NOT consistent with each other."
    "\n"
    "\n                  Specifically, some functions whose tests passed"
    "\n                         depend upon functions whose tests failed.\n"
    ;

    fprintf
    ( inconsistent_test_results_log
    , ir_log_text_format
    );

    printf
    ( ir_log_text_format
    );
  }

  fclose(inconsistent_test_results_log);


//#############################################################################


  printf
  ("\n###############################################################################"
   "\n"
   "\n  Valgrind Memcheck Result:\n\n"
  );

  return 0;
}
