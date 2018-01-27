= Install deps

 This is for debian based systems. If you don't want to use sudo for the gem install that's fine but make sure you have your gems install to a directory you have write access to.
```
sudo apt-get install ruby ruby-dev libmariadbclient-dev-compat
sudo gem install cinch mysql2 sequel
```

You can use the included witness.sh file from this repository to start the bot, once you've edited witness.yaml to your liking. You'll also need a MySQL or MariaDB database, with a user that has full access to the database. Currently, witness assumes the database is running on localhost.


== TODO
-Make this a plugin, so you can add this DB logging to any cinch bot and not just have to use mine
-Better error handling, right now I'm letting cinch handle it all
-Anything else I can think of.

