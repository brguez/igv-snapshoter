
cd /Users/brodriguez/Research/Scripts/Bash/igv-snapshoter

## Create git repository:
git init

## Basic configuration
git config --global user.name "brguez"
git config --global user.email rodriguezmartinbernardo@gmail.com
git config --global core.editor emacs

## Create SSH key and add to my github account
https://help.github.com/articles/generating-an-ssh-key/
cat ~/.ssh/id_rsa

## First commit and add to github

git add README.md
git commit -m "first commit"
git remote add origin git@github.com:brguez/igv-snapshoter.git
git push -u origin master


