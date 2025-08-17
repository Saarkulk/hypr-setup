function fish_right_prompt
    # You can pass 0 as the last status when you are not using STATUS or SIGSTATUS
	fishline -s 0 -r exectime git clock
end