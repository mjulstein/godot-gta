#!/usr/bin/env bash
set -euo pipefail

publish_branch="${1:-docs}"
publish_subdir="${2:-docs}"
preset_name="${GODOT_WEB_PRESET:-Web}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

start_branch="$(git branch --show-current)"
if [[ -z "$start_branch" ]]; then
	echo "publish_web_docs.sh requires a checked-out branch." >&2
	exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
	echo "publish_web_docs.sh requires a clean working tree." >&2
	exit 1
fi

if ! command -v godot >/dev/null 2>&1; then
	echo "godot must be installed and available on PATH." >&2
	exit 1
fi

export_dir="$(mktemp -d)"
worktree_dir="$(mktemp -d)"

cleanup() {
	set +e
	if git worktree list --porcelain | grep -Fq "worktree $worktree_dir"; then
		git worktree remove --force "$worktree_dir" >/dev/null 2>&1
	fi
	rm -rf "$export_dir" "$worktree_dir"
	if [[ "$(git branch --show-current)" != "$start_branch" ]]; then
		git checkout "$start_branch" >/dev/null 2>&1
	fi
}

trap cleanup EXIT

HOME=/tmp/godot-home godot --headless --path . --export-release "$preset_name" "$export_dir/index.html"

git worktree prune >/dev/null

if git show-ref --verify --quiet "refs/heads/$publish_branch"; then
	git worktree add "$worktree_dir" "$publish_branch" >/dev/null
elif git ls-remote --exit-code --heads origin "$publish_branch" >/dev/null 2>&1; then
	git worktree add -b "$publish_branch" "$worktree_dir" "origin/$publish_branch" >/dev/null
else
	git worktree add --detach "$worktree_dir" >/dev/null
fi

pushd "$worktree_dir" >/dev/null

if ! git show-ref --verify --quiet "refs/heads/$publish_branch"; then
	git checkout --orphan "$publish_branch" >/dev/null
fi

find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
mkdir -p "$publish_subdir"
cp -R "$export_dir"/. "$publish_subdir"/
touch .nojekyll

git add -A

if git diff --cached --quiet; then
	echo "No web publish changes to push."
	exit 0
fi

GIT_AUTHOR_NAME="Codex" \
GIT_AUTHOR_EMAIL="codex@local.invalid" \
GIT_COMMITTER_NAME="Codex" \
GIT_COMMITTER_EMAIL="codex@local.invalid" \
git commit -m "Publish web build" >/dev/null

git push origin "$publish_branch" --force >/dev/null

popd >/dev/null

if [[ "$(git branch --show-current)" != "$start_branch" ]]; then
	git checkout "$start_branch" >/dev/null
fi

echo "Published '$preset_name' to branch '$publish_branch' under '$publish_subdir/'."
