# Very simple save/restore working directory behaviour
alias this='pwd > ~/.lastworking'
alias cdw='cd $(cat ~/.lastworking)'

