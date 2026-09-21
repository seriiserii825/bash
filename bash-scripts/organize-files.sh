#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

sort_by_extension() {
	read -rp "Расширения через запятую (например png,pdf,jpg): " input
	IFS=',' read -ra exts <<<"$input"
	for ext in "${exts[@]}"; do
		ext="${ext// /}"
		ext="${ext#.}"
		[ -z "$ext" ] && continue

		mkdir -p "$ext"
		local moved=0
		for f in ./*."$ext"; do
			[ -f "$f" ] || continue
			mv -- "$f" "$ext/"
			moved=$((moved + 1))
		done
		echo "Перемещено $moved файл(ов) в '$ext/'"
	done
}

consolidate_folders() {
	read -rp "Папки через запятую (например photos,docs): " input
	IFS=',' read -ra raw_dirs <<<"$input"
	local dirs=()
	for d in "${raw_dirs[@]}"; do
		d="${d// /}"
		d="${d%/}"
		[ -z "$d" ] && continue
		if [ ! -d "$d" ]; then
			echo "ОШИБКА: папки '$d' не существует" >&2
			exit 1
		fi
		dirs+=("$d")
	done

	if [ "${#dirs[@]}" -lt 1 ]; then
		echo "Нужно указать минимум 1 папку" >&2
		exit 1
	fi

	declare -A names_per_dir
	declare -A all_names

	for d in "${dirs[@]}"; do
		local list=""
		for f in "$d"/*; do
			[ -f "$f" ] || continue
			local bn stem
			bn="$(basename "$f")"
			stem="${bn%.*}"
			list+="$stem"$'\n'
			all_names["$stem"]=1
		done
		names_per_dir["$d"]="$list"
	done

	if [ "${#dirs[@]}" -gt 1 ]; then
		local error=0
		for stem in "${!all_names[@]}"; do
			for d in "${dirs[@]}"; do
				if ! grep -qxF "$stem" <<<"${names_per_dir[$d]}"; then
					echo "ОШИБКА: в '$d/' нет файла с именем '$stem'" >&2
					error=1
				fi
			done
		done

		if [ "$error" -ne 0 ]; then
			echo "Папки не совпадают по составу файлов. Отмена." >&2
			exit 1
		fi
	fi

	local dest_root="$HOME/Downloads"
	echo "Раскладываю в $dest_root ..."
	for stem in "${!all_names[@]}"; do
		local dest="$dest_root/$stem"
		mkdir -p "$dest"
		for d in "${dirs[@]}"; do
			for f in "$d"/*; do
				[ -f "$f" ] || continue
				local bn s
				bn="$(basename "$f")"
				s="${bn%.*}"
				if [ "$s" == "$stem" ]; then
					mv -- "$f" "$dest/"
				fi
			done
		done
	done
	echo "Готово."
}

main() {
	echo "1) Разложить файлы текущей папки по расширениям"
	echo "2) Свести одноимённые файлы из подпапок в Downloads"
	read -rp "Выбор: " choice
	case "$choice" in
	1) sort_by_extension ;;
	2) consolidate_folders ;;
	*)
		echo "Неверный выбор" >&2
		exit 1
		;;
	esac
}

main
