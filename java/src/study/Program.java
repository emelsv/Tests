package study;

import java.util.Scanner;
import java.util.ArrayList;
import study.Parent;
import study.Child;
import study.Client;

public class Program{ 
    public static void main (String args[]) throws Exception{
        ArrayList<Parent> al = new ArrayList<Parent>();
        int arr[] = new int[3];
        int sum = 0;
        
        //Parent p = new Parent();
        //Child c =  new Child();
        //p.print();
        //c.print();
        
        al.add(new Parent());
        al.add(new Parent());
        al.add(new Parent());
        
        for(Parent pr : al){
            pr.setSurname("�������" + String.valueOf(al.indexOf(pr)));
            pr.setName("�����" + String.valueOf(al.indexOf(pr)));
            pr.setPatronymic("��������" + String.valueOf(al.indexOf(pr)));
        }
        
        for(Parent pr : al){
            //System.out.println(pr.getName);
            pr.print();
        }
        
        final Client cl = new Client.Builder()
            .Code(1)
            .Name("���� � ������")
            .build();
           
        cl.print();
        
        /*
        Scanner in = new Scanner(System.in);
        
        for(int i = 0; i < 3; i++ ) {
            System.out.print("������� ����� �����: ");
            if (in.hasNextInt() == true) {
                arr[i] = in.nextInt();
            } 
            else {
                throw new Exception("������� �� ����� �����");
            }
            sum += arr[i];
            System.out.println(arr[i]);
        }
        
        System.out.println("Array sum = " + sum);
        */
        System.out.println("Finish...");
    }
}