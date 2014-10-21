package acabit_client.core;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;

import talismane_client.datamodel.Sentence;
import talismane_client.datamodel.Structure;
import talismane_client.datamodel.Token;
import yatea_client.datamodel.Term;

public class ACABITClient {
	
	boolean test = false;
	boolean print;
	
	public ACABITClient(){
		
	}

	public ArrayList<Term> analyse(Structure currStructure)
			throws UnknownHostException, IOException, InterruptedException {
		return this.analyse(currStructure, false);
	}

	public ArrayList<Term> analyse(Structure currStructure, boolean print) throws IOException, InterruptedException {
//		String workingDir = System.getProperty("user.dir");
		
		this.print = print;
		
		String workingDir = "/home/jfaucon/workspace/acabit-client";
		
		
		
		/**
		 * Ecriture
		 */
		this.writeACABITFormat(currStructure, workingDir+"/tmp.txt"); /* write */
		File xml = new File(workingDir+"/out.xml");
		xml.delete();
		
		/**
		 *  Analyse avec YaTea
		 */
		Runtime runtime = Runtime.getRuntime();
		
		String [] cmdarray1 = new String [3];
		cmdarray1 [0] = "perl";
		cmdarray1 [1] = "fr_stat.pl";
		cmdarray1 [2] = workingDir+"/tmp.txt";
		
		String [] envp = new String [0];
		File dir = new File( workingDir+"/");
		
		final Process process = runtime.exec(cmdarray1, envp, dir);
		process.waitFor();
		
		
		String [] cmdarray2 = new String [2];
		cmdarray2 [0] = "perl";
		cmdarray2 [1] = "fr_tri.pl";
		
		final Process process2 = runtime.exec(cmdarray2, envp, dir);
		process2.waitFor();
		
		
		/**
		 *  Récupération des éléments
		 */
		File xml_exist = new File(workingDir+"/out.xml");
		FileInputStream fis = new FileInputStream(xml_exist);
		String str = "";
		LineNumberReader l = new LineNumberReader(new BufferedReader(new InputStreamReader(fis)));
		
		int count = 0;
		while ((str=l.readLine())!=null){
			count = l.getLineNumber();
		}
		
		ArrayList<Term> candidate_terms = new ArrayList<Term>();
		if(count > 0){
			candidate_terms = this.getResults(currStructure, workingDir+"/out.xml");
		}
		
		
//		try {
//		    Thread.sleep(2000);                 //1000 milliseconds is one second.
//		} catch(InterruptedException ex) {
//		    Thread.currentThread().interrupt();
//		}
		
		
		
		return candidate_terms;
	}
	
	
	private ArrayList<Term> getResults(Structure currStructure, String path) throws IOException{
		ArrayList<Term> candidate_terms = new ArrayList<Term>();
		
		SAXBuilder sxb = new SAXBuilder();
		String pathXml =  path;
		
		Document document =  new Document();
		try {
			document =  sxb.build(new File(pathXml));
		} catch (JDOMException e) {
			// TODO Auto-generated catch block
			System.err.println("Error in reading XML");
			e.printStackTrace();
		}

		Element root = document.getRootElement();
		List candidates = root.getChildren("SETCAND");
		Iterator i = candidates.iterator();
		
		// Iteration sur les terms extraits
		while (i.hasNext()) {
			Element setcand = (Element) i.next();
			
			List niv1 =  setcand.getChildren();
			Iterator j = niv1.iterator();
			
			// Iteration de niv1 : CAND 
			while(j.hasNext()){
				Element niv1_element = (Element) j.next();
				
				List niv2 = niv1_element.getChildren();
				Iterator k = niv2.iterator();
				
				while(k.hasNext()){ // Iteration de niv 2 : NA
					Element niv2_element = (Element) k.next();
					
					List niv3 = niv2_element.getChildren();
					Iterator v = niv3.iterator();
					
					while(v.hasNext()){ // MODIF BASE et autre
						Element niv3_element = (Element) v.next();
						
						List niv4 = niv3_element.getChildren();
						Iterator x = niv4.iterator();
						
						while(x.hasNext()){
							Element term = (Element) x.next();
							if(term.getName().equals("TERM")){
								candidate_terms.addAll(associateStructureAndTerm(currStructure,term.getText()));
							}
						}
					}
				}
			}
			
			
		}
		
		return candidate_terms;
	}
	
	private ArrayList<Term> associateStructureAndTerm(Structure currStructure, String term){
		ArrayList<Term> subset_candidate = new ArrayList<Term>();
		
//		System.out.println(term);
		term = term.trim();
		String [] lemma = term.split(" ");
//		System.out.print("\nTERM:");
//		for(int i=0;i<lemma.length;i++){
//			System.out.print(lemma[i]+" ");
//		}
//		System.out.println("");
		ArrayList<ArrayList<Token>> retrieved = new ArrayList<ArrayList<Token>>();
		
		for(Sentence currSentence : currStructure){
			int index_token = 0;
			for(Token currToken : currSentence){
				
				boolean flag = false;
				ArrayList<Token> current = new ArrayList<Token>();
				retrieved.add(current);
				
				for(int j=0;j<lemma.length;j++){
					
					int curr_index = index_token+j;
					if(curr_index < currSentence.size()){
						
						if(currSentence.get(curr_index).getLemma().equals(lemma[j])){
							flag=true;
							
							current.add(currSentence.get(curr_index));
							
						}
						else{
							flag=false;
							retrieved.remove(current);
						}
						
					}
					
				}
				index_token++;
			}
		}
		
		
		for(ArrayList<Token> token : retrieved){
//			System.out.print("FLAG:");
			
			String text = "";
			for(Token currToken2 : token){
//				System.out.print(currToken2.getForm() + " ");
				text += currToken2.getForm() + " ";
			}
			text = text.trim();
			if(print){
				System.out.println(text);
			}
			
			Term newTerm = new Term();
			newTerm.setTokens(token);
			newTerm.setText(text);
			newTerm.setOrigin("acabit");
			
			
			subset_candidate.add(newTerm);
//			System.out.println("");
		}
		
				
		return subset_candidate;
	}
	
public void writeACABITFormat(Structure currStructure, String path) throws IOException{
		
		File outFile = new File(path);
		Writer destFile = null;
		
		destFile = new BufferedWriter(new OutputStreamWriter(
				new FileOutputStream(outFile), "UTF-8"));
		
		String toWrite = "";
		
		toWrite += "<record>\n";
		toWrite += "<AN>\n";
		toWrite += "92/CAR/92 -/- 0014602/CAR/0014602\n";
		toWrite += "</AN>\n";
		
		toWrite += "<AB>\n";
		int ph_nb = 1;
		for(Sentence currSentence : currStructure){
			
			toWrite += "<ph_nb="+ph_nb+">";
			for(Token currToken : currSentence){
				
//				if(this.mapping(currToken).getCppostag().equals("")){
//					System.out.print(currToken.getForm());
//					System.out.print("\t");
//					System.out.print(currToken.getCppostag());
//					System.out.print("\t");
//					System.out.print(currToken.getFeats());
//					System.out.print("\t");
//					System.out.print(currToken.getLemma());
//					System.out.print("\n");
//					System.out.print(this.mapping(currToken));
//					System.out.println("");
//					
//					System.err.println("Erreur ACABIT : postag non reconnu");
//				}
				
				
				// Crade
				String original = this.mapping(currToken);
				String currPostag = currToken.getCppostag();
						
				String posmorpho = "";
				if(currPostag.equals("SBC") || currPostag.equals("DTN") || currPostag.equals("ADJ")){
					String feats = currToken.getFeats();
					String nombre = "_";
					if(feats.contains("n=s")){
						nombre = "s";
					}else if(feats.contains("n=p")){
						nombre = "p";
					}
					String genre = "_";
					if(feats.contains("n=m")){
						genre = "m";
					}else if(feats.contains("n=f")){
						genre = "f";
					}
					
					posmorpho = currPostag+":"+genre+":"+nombre;
				}else if(currPostag.equals("ADV")){
					posmorpho = currPostag;
				}
				else if(currPostag.equals("PREP")){
					posmorpho = currPostag;
				}
				else if(currPostag.equals("COO")){
					posmorpho = currPostag;
				}
				else if(currPostag.equals("PRV")){
					
					String feats = currToken.getFeats();
					String nombre = "_";
					if(feats.contains("n=s")){
						nombre = "s";
					}else if(feats.contains("n=p")){
						nombre = "p";
					}
					String genre = "_";
					if(feats.contains("n=m")){
						genre = "m";
					}else if(feats.contains("n=f")){
						genre = "f";
					}
					String personne = "_";
					if(feats.contains("p=3")){
						personne = "3p";
					}else if(feats.contains("n=p")){
						personne = "_";
					}
					
					posmorpho = currPostag + ":" + personne + ":_:" + nombre + ":" + genre;
					
					
				}
				else{
					posmorpho = currPostag + " " + currToken.getFeats();
				}
				
				
				toWrite += currToken.getForm() + "/" + posmorpho + "/" + currToken.getLemma() + " ";
				if(test){
					toWrite += "\n";
				}
				
				// IMPORTANT  : replace original token
				currToken.setCppostag(original);
				
			}
			ph_nb ++;
			toWrite += "</ph>\n";
		}
		toWrite += "</AB>\n";
		toWrite += "</record>\n";
		
		destFile.write(toWrite);
		destFile.close();
		
	}
	
	public String mapping(Token currToken){
		
		String postag = currToken.getCppostag();
		String original = postag;
		String lemma = currToken.getLemma();
		String feats = currToken.getFeats();
		
		String postag_treeTagger = "";
				
		
		if(postag.equals("DET")) {
//			if(lemma.equals("le") || lemma.equals("la") || lemma.equals("les")  ){
//				postag_treeTagger = "DET:ART";
//			}
//			else 
			if( lemma.equals("leur") || lemma.equals("ton") || lemma.equals("ta") || lemma.equals("tes") || lemma.equals("leurs")
					|| lemma.equals("mon") || lemma.equals("ma") || lemma.equals("mes")){
				currToken.setCppostag("DTN");
			}
			else{
				
				if(currToken.getLemma().equals("l'")){
					currToken.setLemma("le");
				}
				if(currToken.getLemma().equals("d'")){
					currToken.setLemma("de");
				}
				currToken.setCppostag("DTN");
			}
		}
		else if(postag.equals("NC")){
			currToken.setCppostag("SBC");
		}
		else if(postag.equals("P")){
			currToken.setCppostag("PREP");
		}
		else if(postag.equals("CC")){
			currToken.setCppostag("COO");
		}
		else if(postag.equals("PONCT")){
			currToken.setCppostag("PUN");
		}
		else if(postag.equals("PRO")){
			currToken.setCppostag("PRO");
		}
		else if(postag.equals("P+D")){
			currToken.setCppostag("DTC");
		}
		else if(postag.equals("ADV")){
			currToken.setCppostag("ADV");
		}
		else if(postag.equals("ADJ")){
			currToken.setCppostag("ADJ");
		}
		else if(postag.equals("VPP")){
			currToken.setCppostag("VER:pper");
		}
		else if(postag.equals("CLS")){
			currToken.setCppostag("PRV");
		}
		else if(postag.equals("VINF")){
			currToken.setCppostag("VNCFF");
		}
		else if(postag.equals("NPP")){
			currToken.setCppostag("SBP");
		}
		else if(postag.equals("V")){
			if(feats.contains("|t=P")){
				currToken.setCppostag("VER:pres");
			}
		}
		else if(postag.equals("PROREL")){
			currToken.setCppostag("PRO:REL");
		}
		else{
//			System.err.println("Erreur dans TreeTaggerMapping pour " + currToken.getCppostag());
		}
		
		if(currToken.getLemma().equals("_")){
			currToken.setLemma(currToken.getForm());
		}
		
		
		return original;
	}

}
