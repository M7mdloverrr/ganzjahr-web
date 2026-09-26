import Nav from "@/components/Nav";
import Hero from "@/components/Hero";
import Services from "@/components/Services";
import Guarantees from "@/components/Guarantees";
import YearWheel from "@/components/YearWheel";
import PriceCalculator from "@/components/PriceCalculator";
import WinterRadar from "@/components/WinterRadar";
import BeforeAfter from "@/components/BeforeAfter";
import Process from "@/components/Process";
import References from "@/components/References";
import Contact from "@/components/Contact";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <Services />
        <Guarantees />
        <YearWheel />
        <PriceCalculator />
        <WinterRadar />
        <BeforeAfter />
        <Process />
        <References />
        <Contact />
      </main>
      <Footer />
    </>
  );
}
