package study;

import study.Parent;

public class Child extends Parent {
    @Override
    public void print(){
        System.out.println("Child");
        System.out.println("Surname: " + this.surname);
        System.out.println("Name: " + this.name);
        System.out.println("Patronymic: " + this.patronymic);
    }
}