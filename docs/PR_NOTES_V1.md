# V1 PR review notes

Review this branch as an initial V1 implementation, not as a merge-ready release. The next gate is live pre-flight and BSPWM validation on the bare-metal Legion, followed by a VMware Kali guest test.

Key review areas:

1. installer does not confuse VMware Workstation host with a VMware guest
2. rollback protects existing dotfiles and login shell
3. display helper never forces a named output/resolution
4. dynamic modules do not assume interface or battery names
5. standard `cat` and Vim behavior remain intact
6. Flameshot owns screenshot bindings
7. V2 login/greeter work remains out of scope
