clean-logs:
	rm -f ~/.config/nvim/logs/*
	touch ${HOME}/.config/nvim/logs/nvim_acid_log

logs:
	tail -f ${HOME}/.config/nvim/logs/nvim_acid_log

push:
	git push && nvr -c 'PlugUpdate acid.nvim'
