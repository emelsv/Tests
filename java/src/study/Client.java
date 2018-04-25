package study;

public class Client {
    public final int Code;
    public final String Name;
    
    private Client(int code, String name){
        this.Code = code;
        this.Name = name;
    }
    
    public void print(){
        System.out.println("Client");
        System.out.println("Code: " + this.Code);
        System.out.println("Name: " + this.Name);            
    }
    
    public static class Builder {
        private int Code;
        private String Name;
        
        public Builder Code(int code){
            this.Code = code;
            return this;
        }

        public Builder Name(String name){
            this.Name = name;
            return this;
        }
        
        public Client build() {
            return new Client(this.Code, this.Name);
        }
    }
}