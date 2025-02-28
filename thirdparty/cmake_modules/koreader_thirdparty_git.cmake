find_package(Git)

function(_ko_write_gitclone_script script_filename git_EXECUTABLE git_repository git_tag git_submodules src_name work_dir build_source_dir gitclone_infofile gitclone_stampfile)
  file(WRITE ${script_filename}
"if(\"${git_tag}\" STREQUAL \"\")
  message(FATAL_ERROR \"Tag for git checkout should not be empty.\")
endif()

set(run 0)

######################################################################
# 1. if not cloned before, do a git clone
# 2. are we already at the given commit hash?
#   2.1. if not git fetch && checkout
# 4. git submodules update
# 5. copy everything over to source directory
######################################################################

if(\"${gitclone_infofile}\" IS_NEWER_THAN \"${gitclone_stampfile}\")
  set(run 1)
endif()

if(NOT run)
  message(STATUS \"Avoiding repeated git clone, stamp file is up to date: '${gitclone_stampfile}'\")
  return()
endif()

set(should_clone 1)
if(EXISTS \"${work_dir}\")
  if(EXISTS \"${work_dir}/${src_name}\")
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" rev-parse HEAD
      WORKING_DIRECTORY \"${work_dir}/${src_name}\"
      RESULT_VARIABLE error_code
      OUTPUT_VARIABLE output
    )
    if(error_code)
      message(\"Failed to read current tag, recloning the repo...\")
      file(REMOVE_RECURSE \"${work_dir}/${src_name}\")
    else()
      string(STRIP \"\${output}\" curr_tag)
      set(should_clone 0)
    endif()
  endif()
else()
  make_directory(\"${work_dir}\")
endif()

if(should_clone)
  # try the clone 3 times incase there is an odd git clone issue
  set(error_code 1)
  set(number_of_tries 0)
  while(error_code AND number_of_tries LESS 3)
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" clone \"${git_repository}\" \"${src_name}\"
      WORKING_DIRECTORY \"${work_dir}\"
      RESULT_VARIABLE error_code
    )
    math(EXPR number_of_tries \"\${number_of_tries} + 1\")
  endwhile()
  if(number_of_tries GREATER 1)
    message(STATUS \"Had to git clone more than once:
            \${number_of_tries} times.\")
  endif()
  if(error_code)
    message(FATAL_ERROR \"Failed to clone repository: '${git_repository}'\")
  endif()
endif()

if(NOT \"\${curr_tag}\" STREQUAL \"${git_tag}\")
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" checkout ${git_tag}
    WORKING_DIRECTORY \"${work_dir}/${src_name}\"
    RESULT_VARIABLE error_code
  )
  if(error_code)
    message(FATAL_ERROR \"Failed to checkout tag: '${git_tag}'\")
  endif()
endif()

# checkout all submodules
execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule init ${git_submodules}
  WORKING_DIRECTORY \"${work_dir}/${src_name}\"
  RESULT_VARIABLE error_code
)
if(error_code)
  message(FATAL_ERROR \"Failed to init submodules in: '${work_dir}/${src_name}'\")
endif()

execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule update --recursive ${git_submodules}
  WORKING_DIRECTORY \"${work_dir}/${src_name}\"
  RESULT_VARIABLE error_code
)
if(error_code)
  message(FATAL_ERROR \"Failed to update submodules in: '${work_dir}/${src_name}'\")
endif()

# Complete success, update the script-last-run stamp file:
execute_process(
  COMMAND \${CMAKE_COMMAND} -E copy
    \"${gitclone_infofile}\"
    \"${gitclone_stampfile}\"
  WORKING_DIRECTORY \"${work_dir}/${src_name}\"
  RESULT_VARIABLE error_code
)
if(error_code)
  message(FATAL_ERROR \"Failed to copy script-last-run stamp file: '${gitclone_stampfile}'\")
endif()

# Copy everything over to source directory
get_filename_component(destination_dir \"${build_source_dir}\" PATH)
if(EXISTS ${build_source_dir})
  file(REMOVE_RECURSE ${build_source_dir})
endif()
file(COPY ${work_dir}/${src_name} DESTINATION \${destination_dir})
"
)
endfunction()

function(ko_write_gitclone_script script_filename git_repository git_tag build_source_dir)
    set(clone_dir ${CMAKE_CURRENT_SOURCE_DIR}/build/git_checkout)
    set(work_dir ${CMAKE_CURRENT_BINARY_DIR}/git_checkout)
    set(tmp_dir ${work_dir}/tmp)
    set(stamp_dir ${work_dir}/stamp)
    set(git_submodules ${ARGV4})

    set(${script_filename} ${tmp_dir}/${PROJECT_NAME}-gitclone.cmake)
    set(${script_filename} ${${script_filename}} PARENT_SCOPE)

    configure_file(
      "${CMAKE_ROOT}/Modules/RepositoryInfo.txt.in"
      "${stamp_dir}/${PROJECT_NAME}-gitinfo.txt"
      @ONLY
    )
    _ko_write_gitclone_script(
        ${${script_filename}}
        ${GIT_EXECUTABLE}
        ${git_repository}
        ${git_tag}
        "${git_submodules}"
        ${PROJECT_NAME}
        ${clone_dir}
        ${build_source_dir}
        ${stamp_dir}/${PROJECT_NAME}-gitinfo.txt
        ${stamp_dir}/${PROJECT_NAME}-gitclone-lastrun.txt
    )
endfunction()
