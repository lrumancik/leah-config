# generic stuff
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias git_trace='git log --follow -p -U20'
alias plog='git log --format="%C(auto) %H %s %d"'
alias amend='git commit --amend --no-edit'
alias glg='git log --no-merges --grep'
alias glgm='git log upstream/master --no-merges --grep'
alias gcp='git cherry-pick'

# temp aliases to reverse git bisect good/bas
alias commit-broken='git bisect good'
alias commit-good='git bisect bad'

unalias search &>/dev/null | true
search() {
    flags="-rIn"

    if test "$1" = "-i"; then
	flags+="i"
	shift
    fi

    target="$@"

    echo "grep $flags"

    declare -a exclude=("System.map" "*.tmp*" "*.cmd*" "*.o*" "*.img*")
    declare -a exclude_dir=(".git" "gbuild-obj" "__pycache__" "*var.lib.apt.lists")

    if test -d .git ; then
	worktrees=$(git worktree list | cut -f1 -d ' ')

	for tree in $worktrees; do
	    if [ "$(pwd)" = "$tree" ]; then
		continue
	    fi

	    # get relative path
	    tree=${tree#"$(pwd)/"}
	    exclude_dir+=("$tree")
	done
    fi

    exclude_str=""

    echo "  --exclude"
    for ex in ${exclude[@]}; do
	exclude_str+=" --exclude=$ex"
	echo "    $ex"
    done

    echo "  --exclude_dir"
    for ex in ${exclude_dir[@]}; do
	exclude_str+=" --exclude-dir=$ex"
	echo "    $ex"
    done

    echo "target=$target"

    grep $flags $exclude_str "$target"
}

find_open() {
	file=$1

	find_results=$(find . -name $file)
	if test -z "$find_results"; then
		echo "Did not find match"
		return
	fi

	worktrees=$(git worktree list | cut -f1 -d ' ')
	for tree in $worktrees; do
		if [ "$(pwd)" = "$tree" ]; then
			continue
		fi

		# get relative path
		tree=${tree#"$(pwd)/"}
		find_results=$(echo "$find_results" | sed "s:\.\/$tree.*$::g" | sed '/^[[:space:]]*$/d' )
	done

	if test -z "$find_results"; then
		echo "Did not find match"
		return
	fi

	lines=$(echo "$find_results" | wc -l)
	full_path=$(echo "$find_results" | head -n1)
	if test $lines -gt 1; then
		echo "Found mulitple matches:"
		echo "$find_results"
		echo "Opening $full_path"
		sleep 4
	else
		echo "Opening $full_path"
		sleep 1
	fi

	vi $full_path
}

remove_files_from_commit () {
	git reset --soft HEAD~1
	git restore --staged "$@"
	git commit -C ORIG_HEAD
}

diff_diffs () {
	commit1="$1"
	commit2="$2"

	git show "$1" > /tmp/commit1
	git show "$2" > /tmp/commit2

	diff /tmp/commit1 /tmp/commit2

	rm /tmp/commit1 /tmp/commit2
}


# check_no_changes_rebase <orig branch> <# commits orig> <rebased branch>
# find all files modified in last <# commits> of <orig branch>
# diff these files between orig branch and rebased branch
# if nothing is returned, no changes occured during the rebase
check_no_changes_rebase() {
  local branch_orig=$1
  local branch_orig_commits=$2
  local branch_rebased=$3

  if [ $# -ne 3 ]; then
    echo "requires 3 args:"
    echo "check_no_changes_rebase <orig branch> <# commits orig> <rebased branch>"
    return 1
  fi

  if [ -z "$(git branch --list $branch_orig)" ]; then
    echo "could not find branch $branch_orig in current directory"
    return 1
  fi

  if [ -z "$(git branch --list $branch_rebased)" ]; then
    echo "could not find branch $branch_rebased in current directory"
    return 1
  fi

  echo "git diff-tree $branch_orig~$branch_orig_commits..$branch_orig --no-commit-id --name-only -r"
  files=$(git diff-tree $branch_orig~$branch_orig_commits..$branch_orig --no-commit-id --name-only -r)

  echo "found files:"
  echo "$files"

  for file in $files; do
    git diff $branch_orig $branch_rebased -- $file
  done
}

