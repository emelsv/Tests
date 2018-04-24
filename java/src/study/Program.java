package study;

import java.util.Scanner;
import study.Parent;
import study.Child;

public class Program{ 
    public static void main (String args[]) throws Exception{
        int a;
        Parent p = new Parent();
        Child c =  new Child();
        p.print();
        c.print();
        
        Scanner in = new Scanner(System.in);
        System.out.print("¬ведите целое число: ");
        if (in.hasNextInt() == true) {
            a = in.nextInt();
        } 
        else {
            throw new Exception("¬ведено не целое число");
        }
        
        System.out.println(a);
        System.out.println("Bla Bla Bla!");
    }
}