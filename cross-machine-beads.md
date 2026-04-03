
 how to use beads on a project with other people, where I want my beads  
  to be personal and not be in their face? i can add $repo/.beads to        
  gitignore, but then the beads aren't synchronized with my other           
  machines. i can set beads_dir env to ~/.beads but then it's the same db   
  for all projects

...

● Done. It's now at .claude/commands/setup-beads-sync.md — project-level,
  available to any agent working in this repo. It's already showing up in
  the skills list as /setup-beads-sync.

...


write a prompt I can use to handoff the task of creating a private GH dolt repo for any given project and configuring beads to use it.

...

test

...

● Done. Your personal beads for bd-main are set up:

  - Local: ~/.beads-planning/bd-main/                                       
  - Remote: github.com/maphew/beads-planning-bd-main (private)
  - Prefix: plan-                                                           
  - Sync: bd dolt push / bd dolt pull from within ~/.beads-planning/bd-main/
                                                                            
  The repos.additional config step failed because bd-main itself doesn't    
  have beads initialized locally. When you do have a project with local     
  beads, run bd config set repos.additional "~/.beads-planning/bd-main"     
  there to get hydrated views across both.                  
        
  To bootstrap on another machine:                                          
   
  mkdir -p ~/.beads-planning/bd-main                                        
  cd ~/.beads-planning/bd-main                              
  git init
  bd init --prefix plan
  bd dolt remote add origin
  git+ssh://git@github.com/maphew/beads-planning-bd-main.git                
  bd bootstrap   # or: bd dolt pull
