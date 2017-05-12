using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication6
{
    class Program
    {
        static void Main(string[] args)
        {
            A a = new A();
            a.Test();

            A b = new B();
            b.Test();

            A c = new C();
            c.Test();

            C c1 = new C();
            c1.Test();

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }


    public class A
    {
        public virtual void Test()
        {
            Console.WriteLine("Class A");
        }
    }

    public class B : A
    {
        public override void Test()
        {
            Console.WriteLine("Class B");
        }
    }

    public class C : A
    {
        public new void Test()
        {
            Console.WriteLine("Class C");
        }
    }
}
