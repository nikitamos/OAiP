#!/usr/bin/sh
if [ -d res ]
then
  echo 'Symlink `res` alredy exists' 
else
  # Костыль, чтобы latex нашел картинки, подключаемые из md
  echo 'Creating symlink `res`'
  ln -s 1-18/res res
fi
latexmk