package study;

public class Parent{
    protected String surname;
    protected String name;
    protected String patronymic;
    
    public String getSurname(){
        return this.name;
    }

    public void setSurname(String value)
    {
        if (this.surname != value) {
            this.surname = value;
        }
    }

    public String getName(){
        return this.name;
    }

    public void setName(String value)
    {
        if (this.name != value) {
            this.name = value;
        }
    }
    
    public String getPatronymic(){
        return this.patronymic;
    }

    public void setPatronymic(String value)
    {
        if (this.patronymic != value) {
            this.patronymic = value;
        }
    }
    
    public void print(){
        System.out.println("Parent");
        System.out.println("Surname: " + this.surname);
        System.out.println("Name: " + this.name);
        System.out.println("Patronymic: " + this.patronymic);
    }   
}