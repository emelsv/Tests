@echo Compile...
@javac -sourcepath ./src -d bin src/study/Program.java
@echo Run
@java -classpath ./bin study.Program
